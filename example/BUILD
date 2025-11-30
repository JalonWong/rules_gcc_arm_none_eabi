package(default_visibility = ["//visibility:public"])
load("@rules_gcc_arm_none_eabi//:gen.bzl", "gen_bin", "gen_hex", "gen_asm", "cmd_to_file")

cc_library(
    name = "example_lib",
    srcs = [
        "lib.c",
        "lib.cc",
    ],
)

gen_asm(
    name = "app_asm.txt",
    input = ":example_lib",
)

cmd_to_file(
    name = "symbols.txt",
    input = ":example_lib",
    cmd = "arm-none-eabi-nm",
    args = [
        "--print-size",
        "--numeric-sort",
        "$(input)"
    ]
)

filegroup(
    name = "example",
    srcs = ["app_asm.txt", "symbols.txt"],
)
