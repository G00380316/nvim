-- R Markdown: chunks are found with their language and options.
local rmarkdown = require("rmarkdown")

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Title",
    "```{r setup, include=FALSE}",
    "x <- 1",
    "```",
    "text",
    "```{python}",
    "print(1)",
    "```",
    "```r",
    "y <- 2",
    "```",
})
local chunks = rmarkdown.chunks(buf)
T.eq(#chunks, 3, "three chunks")
T.eq(chunks[1].lang, "r", "first is R")
T.eq(chunks[1].options, "setup, include=FALSE", "options after the language")
T.eq({ chunks[1].first, chunks[1].last }, { 3, 3 }, "first chunk lines")
T.eq(chunks[2].lang, "python", "second is python")
T.eq(chunks[3].lang, "r", "a plain ```r fence is R")
T.eq(rmarkdown.is_rmd(buf), false, "a scratch buffer is not an Rmd")
