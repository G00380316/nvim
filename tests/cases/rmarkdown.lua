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

-- A failed render names the packages it lacked.
T.eq(rmarkdown.missing_packages("Error in `library()`:\n! there is no package called 'tidyverse'"), { "tidyverse" }, "straight quotes")
T.eq(rmarkdown.missing_packages("there is no package called ‘ggplot2’\nthere is no package called ‘dplyr’\nthere is no package called ‘ggplot2’"),
    { "ggplot2", "dplyr" }, "curly quotes, each once")
T.eq(rmarkdown.missing_packages("some other error"), {}, "nothing missing")

-- Quarto options: `#| eval: false` turns a chunk off, like eval=FALSE does.
local q = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(q, 0, -1, false, {
    "```{r}",
    "#| eval: false",
    "x <- 1",
    "```",
    "```{r}",
    "#| echo: false",
    "y <- 2",
    "```",
})
local qchunks = rmarkdown.chunks(q)
T.eq(#qchunks, 2, "two quarto chunks")
