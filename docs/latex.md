Pandoc LaTeX images
==================================================================

These images contain [pandoc][], the universal document converter,
and a basic [LaTeX] installation for conversions to PDF.

Using pandoc together with [LaTeX] is a popular option to create
PDF files from other formats. This image provides a [TeX Live]
installation and contains all packages required to produce a PDF
with pandoc's default options.

[pandoc]: https://pandoc.org/
[LaTeX]: https://latex-project.org/
[TeX Live]: https://www.tug.org/texlive/

``` include
docs/sections/quick-reference.md
```

``` include
docs/sections/supported-tags.md
```

Supported stacks <a name="supported-stacks"></a>
------------------------------------------------------------------

All tags can be suffixed with a stack-identifier, e.g.,
`latest-alpine`. This allows to chose a specific operation system.
Available stacks are

- *alpine*: [Alpine] Linux.

[Alpine]: https://alpinelinux.org/
[Ubuntu]: https://ubuntu.org/

``` include
docs/sections/run.md
```

TeXLive Version
------------------------------------------------------------------

The TeXLive version for each tag is fixed. See the table below
for the version associated with a given tag / pandoc version.

``` texlive-versions
```

Note that, due to the way TeXLive releases work, users who build
derivative images may experience problems if the TeXLive version
has been newly frozen. This can be resolved by pulling the
updated base image again.
