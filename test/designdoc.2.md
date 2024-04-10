# Markdown tips

## Blocks

### Admonition blocks

The markdown can include admonition blocks for text that need special attention.

The following blocks are supported: **warning**, **important**, **note**, **caution**, **tip**.

For example:

::: warning
This text is in a warning admonition block.
:::

::: important
This text is in a important admonition block.
:::

::: note
This text is in a note admonition block.
:::

::: caution
This text is in a caution admonition block.
:::

::: tip
This text is in a tip admonition block.
:::

### Code blocks

Code blocks begin with a row of three or more backticks (`) and end with a row of backticks that must be at least as long as the starting row.

Everything between these lines is treated as code. No indentation is necessary:

```
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
```

Code blocks must be separated from surrounding text by blank lines.

If the code itself contains a row of backticks, use a longer row of tildes or backticks at the start and end:

````
```
code including tildes
```
````

A shortcut form can be used for specifying the language of the code block:

```json
{
  "author": [],
  "block-headings": true,
  "colorlinks": true,
  "date": "April 08, 2024",
  "disable-header-and-footer": false,
  "disclaimer": "This document contains business and trade secrets (essential information about Innofactor's business) and is therefore totally confidential. Confidentiality does not apply to pricing information",
  "page-numbers": true,
  "geometry": "a4paper,left=2.54cm,right=2.54cm,top=1.91cm,bottom=2.54cm",
  "links-as-notes": true,
  "listings-disable-line-numbers": false,
  "listings-no-page-break": false,
  "lof": false,
  "logo": "/.pandoc/templates/designdoc-logo.png",
  "lot": false,
  "mainfont": "Carlito",
  "pandoc-latex-environment": {
    "warningblock": ["warning"],
    "importantblock": ["important"],
    "noteblock": ["note"],
    "cautionblock": ["caution"],
    "tipblock": ["tip"]
  },
  "project": "",
  "subtitle": "",
  "table-use-row-colors": false,
  "tables": true,
  "title": "",
  "titlepage": true,
  "titlepage-color": "FFFFFF",
  "titlepage-text-color": "5F5F5F",
  "titlepage-top-cover-image": "/.pandoc/templates/designdoc-cover.png",
  "toc": true,
  "toc-own-page": true,
  "toc-title": "Table of Contents",
  "version-history": []
}
```

To cause the lines of the code block to be numbered, use:

```haskell {.numberLines startFrom="1"}
qsort [] = []
```

The numberLines class will cause the lines of the code block to be numbered, starting with 1 or the value of the startFrom attribute.

### Line blocks

A line block is a sequence of lines beginning with a vertical bar (|) followed by a space. The division into lines will be preserved in the output, as will any leading spaces; otherwise, the lines will be formatted as Markdown. This is useful for verse and addresses:

| The limerick packs laughs anatomical
| In space that is quite economical.
| But the good ones I've seen
| So seldom are clean
| And the clean ones so seldom are comical

## Footnotes

Footnotes use the following syntax:

Here is a footnote reference,[^1] and another.[^longnote]

[^1]: Here is the footnote.
[^longnote]: Here's one with multiple blocks.

    Subsequent paragraphs are indented to show that they
    belong to the previous footnote.

        { some.code }

    The whole paragraph can be indented, or just the first
    line. In this way, multi-paragraph footnotes work like
    multi-paragraph list items.

This paragraph won't be part of the note, because it
isn't indented.

The identifiers in footnote references may not contain spaces, tabs, newlines, or the characters ^, [, or ]. These identifiers are used only to correlate the footnote reference with the note itself; in the output, footnotes will be numbered sequentially.

The footnotes themselves need not be placed at the end of the document. They may appear anywhere except inside other block elements (lists, block quotes, tables, etc.). Each footnote should be separated from surrounding content (including other footnotes) by blank lines.

Inline footnotes, unlike regular notes, cannot contain multiple paragraphs. The syntax is as follows:

Here is an inline note.^[Inline notes are easier to write, since
you don't have to pick an identifier and move down to type the
note.]

## Heading identifiers

To link to a heading `# Heading identifiers in HTML` you can simply write `[Heading identifiers in HTML]`.

## Lists

### Task lists

Task lists can be used with the syntax of GitHub-Flavored Markdown:

- [ ] an unchecked task list item
- [x] checked item

## Paragraphs

A backslash followed by a newline is a hard line break.

Note: in multiline and grid table cells, this is the only way to create a hard line break, since trailing spaces in the cells are ignored.

## Tables

A caption may optionally be provided with tables. A caption is a paragraph beginning with the string Table: (or table: or just :), which will be stripped off. It may appear either before or after the table.

### Grid tables

Grid tables look like this:

: Sample grid table.

+---------------+---------------+--------------------+
| Fruit | Price | Advantages |
+===============+===============+====================+
| Bananas | $1.34 | - built-in wrapper |
| | | - bright color |
+---------------+---------------+--------------------+
| Oranges | $2.10 | - cures scurvy |
| | | - tasty |
+---------------+---------------+--------------------+

Cells can span multiple columns or rows:

+---------------------+----------+
| Property | Earth |
+=============+=======+==========+
| | min | -89.2 °C |
| Temperature +-------+----------+
| 1961-1990 | mean | 14 °C |
| +-------+----------+
| | max | 56.7 °C |
+-------------+-------+----------+

A table header may contain more than one row:

+---------------------+-----------------------+
| Location | Temperature 1961-1990 |
| | in degree Celsius |
| +-------+-------+-------+
| | min | mean | max |
+=====================+=======+=======+=======+
| Antarctica | -89.2 | N/A | 19.8 |
+---------------------+-------+-------+-------+
| Earth | -89.2 | 14 | 56.7 |
+---------------------+-------+-------+-------+

Alignments can be specified as with pipe tables, by putting colons at the boundaries of the separator line after the header:

+---------------+---------------+--------------------+
| Right | Left | Centered |
+==============:+:==============+:==================:+
| Bananas | $1.34 | built-in wrapper |
+---------------+---------------+--------------------+

For headerless tables, the colons go on the top line instead:

+--------------:+:--------------+:------------------:+
| Right | Left | Centered |
+---------------+---------------+--------------------+

A table foot can be defined by enclosing it with separator lines that use = instead of -:

+---------------+---------------+
| Fruit | Price |
+===============+===============+
| Bananas | $1.34 |
+---------------+---------------+
| Oranges | $2.10 |
+===============+===============+
| Sum | $3.44 |
+===============+===============+

The foot must always be placed at the very bottom of the table.

### Pipe tables

Pipe tables look like this:

| Right | Left | Default | Center |
| ----: | :--- | ------- | :----: |
|    12 | 12   | 12      |   12   |
|   123 | 123  | 123     |  123   |
|     1 | 1    | 1       |   1    |

The beginning and ending pipe characters are optional, but pipes are required between all columns. The colons indicate column alignment as shown. The header cannot be omitted. To simulate a headerless table, include a header with blank cells.

Since the pipes indicate column boundaries, columns need not be vertically aligned, as they are in the above example.

The cells of pipe tables cannot contain block elements like paragraphs and lists, and cannot span multiple lines. If any line of the Markdown source is longer than 100 characters, then the table will take up the full text width and the cell contents will wrap, with the relative cell widths determined by the number of dashes in the line separating the table header from the table body. (For example ---|- would make the first column 3/4 and the second column 1/4 of the full text width.) On the other hand, if no lines are wider than column width, then cell contents will not be wrapped, and the cells will be sized to their contents.
