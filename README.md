# gcc-arm-none-eabi Rules for Bazel

## Dependence
- bazel v8+
- python3

## Getting Started
First, install gcc-arm-none-eabi compiler, for example:
```shell
scoop bucket add extras
scoop install gcc-arm-none-eabi
```

Then, add the path of arm-none-eabi-gcc to the environment variable `PATH`.
Ues `arm-none-eabi-gcc --version` to confirm that the environment variable has taken effect.

Add the following to your `MODULE.bazel` file:
```python
bazel_dep(name = "rules_gcc_arm_none_eabi")
git_override(
    module_name="rules_gcc_arm_none_eabi",
    remote="https://github.com/JalonWong/rules_gcc_arm_none_eabi.git",
    branch="main",
)
```

Add the following to your `.bazelrc` file:
```shell
build --incompatible_enable_cc_toolchain_resolution
build --platforms=@rules_gcc_arm_none_eabi//:cm3 # depends on your platform
```

Then, in your `BUILD` file:
```python
cc_library(
    ...
)

cc_binary(
    ...
    linkopts = [
        "-Tsrc/cortex_m.ld",
    ],
)
```

## Platforms
- cm3 - Cortex M3
- cm4 - Cortex M4.fp.sp (Hardware float point)
- cm4s - Cortex M4 (software float point)
- cm23 - Cortex M23
- cm33 - Cortex M33

## Generate artifacts
```python
load("@rules_gcc_arm_none_eabi//:gen.bzl", "gen_bin", "gen_hex", "gen_asm", "cmd_to_file")

cc_binary(
    name = "app.elf",
    linkopts = [
        "-Tsrc/cortex_m.ld",
    ],
    ...
)

gen_bin(
    name = "app.bin",
    input = ":app.elf",
)

gen_hex(
    name = "app.hex",
    input = ":app.elf",
)

gen_asm(
    name = "app_asm.txt",
    input = ":app.elf",
)

cmd_to_file(
    name = "symbols.txt",
    input = ":app.elf",
    cmd = "arm-none-eabi-nm",
    args = [
        "--print-size",
        "--numeric-sort",
    ]
)
```
## Build Example
```shell
cd example
bazel build example
```
