Minimal pandoc images
==================================================================

These images contain [pandoc][], the universal document converter.
Containers are stripped down to a bare minimum as far as sensible:
The "static" images contain only a statically compiled pandoc
binary, whereas the other images also contain a minimal operating
system.

[pandoc]: https://pandoc.org/

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
