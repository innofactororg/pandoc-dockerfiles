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

This paragraph won't be part of the note, because it
isn't indented.

The identifiers in footnote references may not contain spaces, tabs, newlines, or the characters ^, [, or ]. These identifiers are used only to correlate the footnote reference with the note itself; in the output, footnotes will be numbered sequentially.

The footnotes themselves need not be placed at the end of the document. They may appear anywhere except inside other block elements (lists, block quotes, tables, etc.). Each footnote should be separated from surrounding content (including other footnotes) by blank lines.

Inline footnotes, unlike regular notes, cannot contain multiple paragraphs. The syntax is as follows:

Here is an inline note.^[Inline notes are easier to write, since
you don't have to pick an identifier and move down to type the
note.]

## Heading identifiers

To link to a heading `# Footnotes` you can simply write [Footnotes].

## Images

![Image text](/.pandoc/templates/designdoc-logo.png){ width=50% }

## Lists

### Task lists

Task lists can be used with the syntax of GitHub-Flavored Markdown:

- [ ] an unchecked task list item
- [x] checked item

## Paragraphs

A backslash followed by a newline is a hard line break.

Note: in multiline table cells, this is the only way to create a hard line break, since trailing spaces in the cells are ignored.

## Tables

A caption may optionally be provided with tables. A caption is a paragraph beginning with the string Table: (or table: or just :), which will be stripped off. It may appear either before or after the table.

### Multiline tables

Multiline tables allow header and table rows to span multiple lines of text (but cells that span multiple columns or rows of the table are not supported). Here is an example:

-----------------------------------------------------------------------------------------------------------------------------------
 Centered   Default           Right Left
  Header    Aligned         Aligned Aligned
----------- ------- --------------- -----------------------------------------------------------------------------------------------
   First    row                12.0 Example of a row that spans multiple lines and is really wide you know. Lets see how this goes.
                                    This is the second line. Hooray.

  Second    row                 5.0 Here's another one. Note
                                    the blank line between
                                    rows.
-----------------------------------------------------------------------------------------------------------------------------------

Table: Here's the caption. It, too, may span
multiple lines.

The header and table rows must each fit on one line. Column alignments are determined by the position of the header text relative to the dashed line below it:

- The table must begin with a row of dashes, before the header text (unless the header row is omitted).
- The table must end with a row of dashes, then a blank line.
- The rows must be separated by blank lines.
- If the dashed line is flush with the header text on the right side but extends beyond it on the left, the column is right-aligned.
- If the dashed line is flush with the header text on the left side but extends beyond it on the right, the column is left-aligned.
- If the dashed line extends beyond the header text on both sides, the column is centered.
- If the dashed line is flush with the header text on both sides, the default alignment is used (in most cases, this will be left).

In multiline tables, the table parser pays attention to the widths of the columns, and the writers try to reproduce these relative widths in the output. So, if you find that one of the columns is too narrow in the output, try widening it in the Markdown source.

The column header row may be omitted, provided a dashed line is used to end the table. For example:

-------     ------ ----------   -------
     12     12        12             12
    123     123       123           123
      1     1          1              1
-------     ------ ----------   -------

: Here's a multiline table without a header.

When the header row is omitted, column alignments are determined on the basis of the first line of the table body. So, in the tables above, the columns would be right, left, center, and right aligned, respectively.

It is possible for a multiline table to have just one row, but the row should be followed by a blank line (and then the row of dashes that ends the table).

### Pipe tables

Pipe tables look like this:

| Right | Left | Default                                                                                                                    | Center |
| ----: | :--- | -------------------------------------------------------------------------------------------------------------------------- | :----: |
|    12 | 12   | Lots of text in this cell. It will wrap but if all cells have lots of text we could be better off using a multiline table. |   12   |
|   123 | 123  | 123                                                                                                                        |  123   |
|     1 | 1    | 1                                                                                                                          |   1    |

The beginning and ending pipe characters are optional, but pipes are required between all columns. The colons indicate column alignment as shown. The header cannot be omitted. To simulate a headerless table, include a header with blank cells.

Since the pipes indicate column boundaries, columns need not be vertically aligned, as they are in the above example.

The cells of pipe tables cannot contain block elements like paragraphs and lists, and cannot span multiple lines. If any line of the Markdown source is longer than 100 characters, then the table will take up the full text width and the cell contents will wrap, with the relative cell widths determined by the number of dashes in the line separating the table header from the table body. (For example ---|- would make the first column 3/4 and the second column 1/4 of the full text width.) On the other hand, if no lines are wider than column width, then cell contents will not be wrapped, and the cells will be sized to their contents.
