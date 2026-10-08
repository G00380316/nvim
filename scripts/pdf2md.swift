// Convert a PDF to Markdown using Apple's PDFKit, with no dependencies.
//
//   pdf2md [--no-ocr] file.pdf   >  note.md
//
// Structure comes from what PDFKit can see: font sizes decide headings, the
// vertical gaps between lines decide paragraphs, and leading bullets or numbers
// decide lists. A page with no text layer -- a scan -- is read with tesseract
// when it is installed. Progress and problems go to stderr, the Markdown to
// stdout, so the output can be redirected as it is.

import AppKit
import Foundation
import PDFKit

setvbuf(stdout, nil, _IOFBF, 1 << 16)

// PDFKit and CoreText log to stderr on every font lookup -- hundreds of lines
// for a short document -- and none of it means anything. Real stderr is kept
// aside for the messages below, and the rest goes nowhere.
let realStderr = dup(2)
let quiet = open("/dev/null", O_WRONLY)
dup2(quiet, 2)

func warn(_ message: String) {
    let data = Data((message + "\n").utf8)
    data.withUnsafeBytes { _ = write(realStderr, $0.baseAddress, data.count) }
}

struct TextLine {
    var text: String
    var size: CGFloat
    var boldRatio: Double
    var top: CGFloat      // bounds.maxY: PDF space grows upwards
    var bottom: CGFloat
    var left: CGFloat
    var page: Int
}

enum Block {
    case heading(Int, String)
    case paragraph(String)
    case bullet(String)
    case numbered(String, String)
    case page(Int)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let allowOCR = !arguments.contains("--no-ocr")
guard let path = arguments.first(where: { !$0.hasPrefix("--") }) else {
    warn("usage: pdf2md [--no-ocr] file.pdf")
    exit(64)
}
guard let document = PDFDocument(url: URL(fileURLWithPath: path)) else {
    warn("cannot open \(path) as a PDF")
    exit(1)
}
if document.isLocked {
    warn("this PDF is password protected")
    exit(2)
}

// MARK: - reading lines with their font

func fontInfo(of selection: PDFSelection) -> (size: CGFloat, boldRatio: Double) {
    guard let attributed = selection.attributedString, attributed.length > 0 else { return (0, 0) }
    var sizes: [CGFloat: Int] = [:]
    var bold = 0
    var total = 0
    attributed.enumerateAttribute(.font, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
        guard let font = value as? NSFont else { return }
        let size = (font.pointSize * 2).rounded() / 2
        sizes[size, default: 0] += range.length
        total += range.length
        if font.fontDescriptor.symbolicTraits.contains(.bold) { bold += range.length }
    }
    let dominant = sizes.max(by: { $0.value < $1.value })?.key ?? 0
    return (dominant, total > 0 ? Double(bold) / Double(total) : 0)
}

func lines(on page: PDFPage, index: Int) -> [TextLine] {
    let area = page.bounds(for: .mediaBox)
    guard let whole = page.selection(for: area) else { return [] }
    var result: [TextLine] = []
    for selection in whole.selectionsByLine() {
        let text = (selection.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { continue }
        let bounds = selection.bounds(for: page)
        let font = fontInfo(of: selection)
        result.append(TextLine(
            text: text, size: font.size, boldRatio: font.boldRatio,
            top: bounds.maxY, bottom: bounds.minY, left: bounds.minX, page: index
        ))
    }
    return result
}

// MARK: - OCR for pages with no text layer

func tesseractPath() -> String? {
    let candidates = ["/opt/homebrew/bin/tesseract", "/usr/local/bin/tesseract", "/usr/bin/tesseract"]
    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
}

func ocr(page: PDFPage) -> String? {
    guard allowOCR, let tesseract = tesseractPath() else { return nil }
    let bounds = page.bounds(for: .mediaBox)
    let scale: CGFloat = 2.5
    let image = page.thumbnail(of: NSSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { return nil }

    let file = FileManager.default.temporaryDirectory.appendingPathComponent("pdf2md-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: file) }
    guard (try? png.write(to: file)) != nil else { return nil }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: tesseract)
    process.arguments = [file.path, "stdout"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(data: data, encoding: .utf8)
}

// MARK: - collect

var all: [TextLine] = []
var scanned: [Int: String] = [:]     // page index -> OCR text
var unreadable: [Int] = []

for index in 0..<document.pageCount {
    guard let page = document.page(at: index) else { continue }
    let found = lines(on: page, index: index)
    if !found.isEmpty {
        all.append(contentsOf: found)
    } else if let text = ocr(page: page), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        scanned[index] = text
    } else {
        unreadable.append(index + 1)
    }
}

// MARK: - what is body text, what is a heading

// The size most of the characters are set in is the body. Anything meaningfully
// larger is a heading, and the larger it is the higher its level.
var weight: [CGFloat: Int] = [:]
for line in all where line.size > 0 { weight[line.size, default: 0] += line.text.count }
let body = weight.max(by: { $0.value < $1.value })?.key ?? 0
let headingSizes = weight.keys.filter { $0 >= body * 1.15 }.sorted(by: >)

func headingLevel(_ line: TextLine) -> Int? {
    if let rank = headingSizes.firstIndex(of: line.size) { return min(rank + 1, 4) }
    // A short, entirely bold line in body size, with no sentence ending, is a
    // heading too -- word processors often do nothing but bold it.
    if line.boldRatio > 0.9, line.text.count <= 60,
       !line.text.hasSuffix("."), !line.text.hasSuffix(","), !line.text.hasSuffix(";") { return 4 }
    return nil
}

func bulletText(_ text: String) -> String? {
    for marker in ["•", "●", "▪", "◦", "·", "-", "–", "—", "*"] where text.hasPrefix(marker + " ") {
        return String(text.dropFirst(marker.count + 1)).trimmingCharacters(in: .whitespaces)
    }
    return nil
}

func numberedText(_ text: String) -> (String, String)? {
    guard let match = text.range(of: #"^\d{1,3}[.)] "#, options: .regularExpression) else { return nil }
    let marker = String(text[match]).trimmingCharacters(in: .whitespaces)
    return (marker, String(text[match.upperBound...]).trimmingCharacters(in: .whitespaces))
}

// MARK: - lines into blocks

var blocks: [Block] = []
var paragraph: [String] = []
var previous: TextLine?
var pageSeen = -1

func join(_ pieces: [String]) -> String {
    var result = ""
    for piece in pieces {
        if result.isEmpty { result = piece; continue }
        // A word split across lines with a hyphen is one word again.
        if result.hasSuffix("-"), let first = piece.first, first.isLowercase {
            result.removeLast()
            result += piece
        } else {
            result += " " + piece
        }
    }
    return result
}

func flushParagraph() {
    guard !paragraph.isEmpty else { return }
    blocks.append(.paragraph(join(paragraph)))
    paragraph = []
}

// The last list item can take continuation lines; a paragraph cannot at once.
var openItem: Int?

func append(toItemAt index: Int, _ extra: String) {
    switch blocks[index] {
    case .bullet(let text): blocks[index] = .bullet(join([text, extra]))
    case .numbered(let marker, let text): blocks[index] = .numbered(marker, join([text, extra]))
    default: break
    }
}

var pages = Set(all.map(\.page)).union(scanned.keys).sorted()
var cursor = 0

func emitScanned(_ page: Int) {
    blocks.append(.page(page + 1))
    guard let text = scanned[page] else { return }
    var chunk: [String] = []
    func flush() {
        if !chunk.isEmpty { blocks.append(.paragraph(join(chunk))); chunk = [] }
    }
    // OCR reads a bullet dot as whatever it most resembles.
    let looksLikeBullet = ["«", "»", "¢", "©", "®"]
    // The list item a following unbroken line belongs to: a wrapped bullet's
    // second line is part of it, not a paragraph of its own.
    var item: Int?
    for raw in text.components(separatedBy: "\n") {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.isEmpty {
            flush()
            item = nil
        } else if let text = bulletText(line) {
            flush()
            blocks.append(.bullet(text))
            item = blocks.count - 1
        } else if let mark = looksLikeBullet.first(where: { line.hasPrefix($0 + " ") }) {
            flush()
            blocks.append(.bullet(String(line.dropFirst(mark.count + 1)).trimmingCharacters(in: .whitespaces)))
            item = blocks.count - 1
        } else if let (marker, text) = numberedText(line) {
            flush()
            blocks.append(.numbered(marker, text))
            item = blocks.count - 1
        } else if let index = item {
            append(toItemAt: index, line)
        } else {
            chunk.append(line)
        }
    }
    flush()
}

for page in pages {
    if scanned[page] != nil { emitScanned(page); continue }

    flushParagraph()
    openItem = nil
    previous = nil
    blocks.append(.page(page + 1))

    for line in all where line.page == page {
        defer { previous = line }

        if let level = headingLevel(line) {
            flushParagraph()
            openItem = nil
            // Consecutive lines of one heading are one heading.
            if case .heading(let existing, let text)? = blocks.last, existing == level, previous?.size == line.size {
                blocks[blocks.count - 1] = .heading(level, join([text, line.text]))
            } else {
                blocks.append(.heading(level, line.text))
            }
            continue
        }

        let gap = previous.map { $0.bottom - line.top } ?? 0
        let spaced = previous != nil && gap > max(line.size, body) * 0.55

        if let item = bulletText(line.text) {
            flushParagraph()
            blocks.append(.bullet(item))
            openItem = blocks.count - 1
        } else if let (marker, item) = numberedText(line.text) {
            flushParagraph()
            blocks.append(.numbered(marker, item))
            openItem = blocks.count - 1
        } else if let index = openItem, !spaced, let before = previous, line.left >= before.left - 1 {
            append(toItemAt: index, line.text)
        } else {
            openItem = nil
            if spaced { flushParagraph() }
            paragraph.append(line.text)
        }
    }
    flushParagraph()
}

// MARK: - write

var output: [String] = []
for block in blocks {
    switch block {
    case .heading(let level, let text): output.append(String(repeating: "#", count: level + 1) + " " + text)
    case .paragraph(let text): output.append(text)
    case .bullet(let text): output.append("- " + text)
    case .numbered(let marker, let text): output.append(marker + " " + text)
    case .page(let number): output.append("<!-- page \(number) -->")
    }
}

// Items of one list sit together; everything else is a block of its own.
var markdown = ""
var lastWasItem = false
for (index, piece) in output.enumerated() {
    let isItem = piece.hasPrefix("- ") || piece.range(of: #"^\d{1,3}[.)] "#, options: .regularExpression) != nil
    if index > 0 { markdown += (isItem && lastWasItem) ? "\n" : "\n\n" }
    markdown += piece
    lastWasItem = isItem
}

if !unreadable.isEmpty {
    let list = unreadable.map(String.init).joined(separator: ", ")
    let reason = !allowOCR ? "OCR was turned off"
        : tesseractPath() == nil ? "install tesseract to read scanned pages"
        : "OCR found nothing"
    markdown += "\n\n<!-- no text on page(s) \(list): \(reason) -->"
    warn("no text on page(s) \(list): \(reason)")
}
warn("read \(document.pageCount) page(s)" + (scanned.isEmpty ? "" : ", OCR on \(scanned.count)"))
print(markdown)
