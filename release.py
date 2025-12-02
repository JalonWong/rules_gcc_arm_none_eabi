import sys
import tarfile
from glob import glob

TAMPLATE = """
`MODULE.bazel`:
```py
bazel_dep(name = "rules_gcc_arm_none_eabi", version = "{version}")
```
"""


if __name__ == "__main__":
    tag = sys.argv[1]

    v = tag.replace("v", "")
    with open("release.md", "w") as f:
        f.write(TAMPLATE.format(version=v))

    with open("MODULE.bazel", "r") as f:
        text = f.read().replace("0.0.0", v)
        with open("MODULE.bazel", "w") as f:
            f.write(text)

    with tarfile.open(f"rules_gcc_arm_none_eabi-{tag}.tar.gz", "w:gz") as tar:
        tar.add("BUILD")
        tar.add("MODULE.bazel")

        files = glob("*.bzl") + glob("toolchain/**", recursive=True)
        for file in files:
            tar.add(file)
