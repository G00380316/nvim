-- A pandoc filter that keeps the Markdown plain.
--
-- GitHub Markdown has no syntax for a few things a Word document or an EPUB is
-- full of, so pandoc's writer falls back to raw HTML for them -- and neither
-- render-markdown nor image.nvim draws HTML:
--
--   a picture with a size and caption   <figure><img style="width:..."></figure>
--   a section or a styled run of text   <div id="ch001_intro">, <span id="...">
--
-- Dropping the size, unwrapping the figure and unwrapping the wrappers leaves
-- ![caption](path) and the text itself, which both plugins do draw.

function Figure(figure)
    return figure.content
end

function Image(image)
    image.attr = pandoc.Attr()
    return image
end

function Div(div)
    return div.content
end

function Span(span)
    return span.content
end
