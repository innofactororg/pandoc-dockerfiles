Core pandoc images
==================================================================

These images contain [pandoc][], the universal document converter,
and a minimal operating system with all tools required for common
conversion tasks.

E.g., the images also contain a program to convert SVG graphics
(svg-convert), as well as the [pandoc-crossref] filter, often used
to number figures, equations, tables and to cross-reference them.

[pandoc]: https://pandoc.org/
[pandoc-crossref]: https://lierdakil.github.io/pandoc-crossref/

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

``` include
docs/sections/run.md
```
