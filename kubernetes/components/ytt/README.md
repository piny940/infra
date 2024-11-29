# ytt libraries

使用例：

```yaml
#! sample.ytt.yaml

#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")

#@ def values():
val: foo
#@ end

#@ lib = library.get("lib-name").with_data_values(values())
--- #@ template.replace(lib.eval())
```

`ytt -f sample.ytt.yaml -f components/ytt/ > "out.yaml"` で yaml 出力される
