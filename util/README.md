### Dev utilities

#### compyfmt

```shell
# run from repo root, use lua 5.1 or luajit
luajit util/compyfmt [file]
# overwrite the original file with -w or --write
luajit util/compyfmt [file] -w
# example
luajit util/compyfmt.lua src/examples/tixy/examples.lua -w
```
