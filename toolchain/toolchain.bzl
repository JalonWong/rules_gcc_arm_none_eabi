load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load(":config.bzl", "arm_gcc_config")

TOOLCHAINS = [
    "cm3",
    "cm4",
    "cm4s",
    "cm23",
    "cm33",
]

def arm_toolchains():
    arm_gcc_config(
        name = "arm_gcc_config_cm3",
        compiler_flags = [
            "-mcpu=cortex-m3",
            "-mthumb",
        ],
        link_flags = [
            "-mcpu=cortex-m3",
            "-mthumb",
        ],
    )

    arm_gcc_config(
        name = "arm_gcc_config_cm4",
        compiler_flags = [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
        ],
        link_flags = [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
        ],
    )

    arm_gcc_config(
        name = "arm_gcc_config_cm4s",
        compiler_flags = [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=soft",
        ],
        link_flags = [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=soft",
        ],
    )

    arm_gcc_config(
        name = "arm_gcc_config_cm23",
        compiler_flags = [
            "-mcpu=cortex-m23",
            "-mthumb",
        ],
        link_flags = [
            "-mcpu=cortex-m23",
            "-mthumb",
        ],
    )

    arm_gcc_config(
        name = "arm_gcc_config_cm33",
        compiler_flags = [
            "-mcpu=cortex-m33",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
        ],
        link_flags = [
            "-mcpu=cortex-m33",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
        ],
    )

    native.filegroup(
        name = "files",
        srcs = [],
    )

    for t in TOOLCHAINS:
        cc_toolchain(
            name = "cc_toolchain_{}".format(t),
            all_files = ":files",
            ar_files = ":files",
            compiler_files = ":files",
            dwp_files = ":files",
            linker_files = ":files",
            objcopy_files = ":files",
            strip_files = ":files",
            supports_param_files = 0,
            toolchain_config = ":arm_gcc_config_{}".format(t),
            toolchain_identifier = "armgcc",
        )

        native.toolchain(
            name = t,
            target_compatible_with = [
                "@rules_gcc_arm_none_eabi//:cortex_{}".format(t[1:]),
            ],
            toolchain = ":cc_toolchain_{}".format(t),
            toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        )
