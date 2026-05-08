# AgentCert LaTeX Project

ARIA: Enterprise Agentic AI Blueprint

## Building the Document

This project uses LuaLaTeX and BibTeX for compilation. The document includes a bibliography that requires multiple compilation passes to resolve all references correctly.

### Full Build Process

To build the complete document with bibliography, run the following commands in order:

```bash
lualatex main.tex
bibtex main
lualatex main.tex
lualatex main.tex
```

### Why Multiple Passes?

1. **First `lualatex` run**: Generates the `.aux` file with citation information
2. **`bibtex` run**: Processes the bibliography from `references.bib` and creates `.bbl` file
3. **Second `lualatex` run**: Incorporates the bibliography into the document
4. **Third `lualatex` run**: Resolves all cross-references and page numbers

### Quick Rebuild

If you've only changed the content (not citations), you can just run:

```bash
lualatex main.tex
```

### Project Structure

- `main.tex` - Main document file
- `references.bib` - Bibliography database
- `infosys-design.cls` - Custom document class
- `assets/` - Cover and TOC hero images
- `images/` - Document figures
- `fonts/` - Custom fonts (Myriad Pro)

### Requirements

- LuaLaTeX (or XeLaTeX)
- BibTeX
- KOMA-Script package
- Custom fonts in `fonts/` directory

### Notes

- The document uses a custom class (`infosys-design`) based on KOMA-Script's `scrbook`
- LuaLaTeX or XeLaTeX is required (pdfLaTeX is not supported)
- The class includes custom page styles, headers, and footers

## Adding Content

### Adding a New Chapter

To add a new chapter to your document, use the `\TNchapter` command:

```latex
\TNchapter[Optional subtitle or description text that appears below the chapter title]{Chapter Title}
\begin{TNtwocol}
\section{Section Title}
Your content here...
\end{TNtwocol}
```

**Example:**
```latex
\TNchapter[Agentic systems represent a shift from static automation to adaptive intelligence.]{Implementation Strategies}
\begin{TNtwocol}
\section{Deployment Considerations}
Content goes here...
\end{TNtwocol}
```

**Notes:**
- The optional parameter (in square brackets) adds a descriptive subtitle with a blue horizontal rule
- `\TNchapter` automatically handles page breaking and styling
- Use `\begin{TNtwocol}...\end{TNtwocol}` for two-column layout within chapters

### Adding Citations

#### Step 1: Add the reference to `references.bib`

Open `references.bib` and add your reference entry:

```bibtex
@article{author2024title,
  title={Article Title},
  author={Author, First and Author, Second},
  journal={Journal Name},
  volume={10},
  number={2},
  pages={123--145},
  year={2024}
}
```

**Common entry types:**
- `@article` - Journal articles
- `@book` - Books
- `@inproceedings` - Conference papers
- `@techreport` - Technical reports
- `@misc` - Websites and other sources

#### Step 2: Cite the reference in your document

In `main.tex`, use the `\cite{}` command:

```latex
According to recent research \cite{author2024title}, agentic systems...
```

For multiple citations:
```latex
Several studies \cite{brown2020language,vaswani2017attention} demonstrate...
```

#### Step 3: Rebuild the document

After adding new citations, run the full build sequence:

```bash
lualatex main.tex
bibtex main
lualatex main.tex
lualatex main.tex
```

The bibliography will automatically update with your new references.
