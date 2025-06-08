""" Config """

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool",
    "tool_path",
    "variable_with_value",
)

# Options -----------------------------------------------------------------------------------------

DEFAULT_COPTS = [
    "-Wall",
    "-Werror",
    "-Wno-comment",
    "-Wno-unused-const-variable",
    "-Wno-unused-function",
    "-Wreturn-type",
    "-fdata-sections",
    "-funsigned-char",
    "-fshort-enums",
    "-g",
    "-gdwarf-3",
    "-ffunction-sections",
]

DEFAULT_CXXOPTS = [
    "-fno-exceptions",
    "-fno-rtti",
]

DEFAULT_LINKOPTS = [
    "-specs=nano.specs",
    "-lc",
    "-lm",
    "-lsupc++_nano",
    "-funsigned-char",
    "-fshort-enums",
    "-ffunction-sections",
    "-fdata-sections",
    "-Wl,--gc-sections",
]

# -------------------------------------------------------------------------------------------------

def wrapper_path(ctx, tool):
    return "{}/bin/arm-none-eabi-{}{}".format("%{arm_root_path}", tool, "%{wrapper_ext}")

def wrapper_tool_path(ctx, tool):
    return tool_path(name = tool, path = wrapper_path(ctx, tool))

def new_feature(name, actions, flags):
    return feature(
        name = name,
        enabled = True,
        flag_sets = [
            flag_set(
                actions = actions,
                flag_groups = [
                    flag_group(flags = flags),
                ] if flags else [],
            ),
        ],
    )

def _config_linker(ctx, features):
    features.append(feature(
        name = "strip_debug_symbols",
        enabled = False,
    ))

    link_flags = []

    inner_link_str = "%{inner_link_flags}"
    if inner_link_str:
        link_flags += inner_link_str.split(" ")

    # Output map file
    map_flag = ["-Wl,-Map=%{output_execpath}.map,--cref"]

    features.append(new_feature(
        "link_flags",
        [
            ACTION_NAMES.cpp_link_executable
        ],
        ctx.attr.link_flags + DEFAULT_LINKOPTS + link_flags + map_flag,
    ))

    features.append(feature(
        name = "user_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_executable,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                    ),
                ],
            ),
        ],
    ))

    features.append(feature(
        name = "libraries_to_link",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_executable,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,-whole-archive"],
                    ),
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["%{libraries_to_link.object_files}"],
                                iterate_over = "libraries_to_link.object_files",
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file"
                                )
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "interface_library",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "static_library"
                                )
                            ),
                        ]
                    ),
                    flag_group(
                        flags = ["-Wl,-no-whole-archive"],
                    ),
                ],
            ),
        ],
    ))

def _impl(ctx):
    tool_paths = [
        wrapper_tool_path(ctx, "gcc"),
        wrapper_tool_path(ctx, "ld"),
        wrapper_tool_path(ctx, "ar"),
        wrapper_tool_path(ctx, "cpp"),
        wrapper_tool_path(ctx, "gcov"),
        wrapper_tool_path(ctx, "nm"),
        wrapper_tool_path(ctx, "objdump"),
        wrapper_tool_path(ctx, "strip"),
    ]

    # action_configs = []
    features = []

    # Assembly flags
    features.append(new_feature(
        "asm_flags",
        [
            ACTION_NAMES.assemble,
            ACTION_NAMES.preprocess_assemble,
        ],
        ["-x", "assembler-with-cpp"],
    ))

    # C flags
    features.append(new_feature(
        "c_flags",
        [
            ACTION_NAMES.assemble,
            ACTION_NAMES.preprocess_assemble,
            ACTION_NAMES.linkstamp_compile,
            ACTION_NAMES.c_compile,
            ACTION_NAMES.lto_backend,
            ACTION_NAMES.clif_match,
        ],
        ctx.attr.compiler_flags + DEFAULT_COPTS + [
            "-fdebug-prefix-map=%{work_dir}=.",
        ],
    ))

    # CPP flags
    features.append(new_feature(
        "cxx_flags",
        [
            ACTION_NAMES.cpp_compile,
            ACTION_NAMES.cpp_header_parsing,
            ACTION_NAMES.cpp_module_compile,
            ACTION_NAMES.cpp_module_codegen,
        ],
        ctx.attr.compiler_flags + DEFAULT_COPTS + DEFAULT_CXXOPTS + [
            "-fdebug-prefix-map=%{work_dir}=.",
        ],
    ))

    # Replace default include flags
    features.append(feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-I", "%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["-I", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    ))

    _config_linker(ctx, features)

    # Compiler include path
    builtin_includes = [
        "%{arm_root_path}/lib/gcc/arm-none-eabi/%{arm_ver}/include",
        "%{arm_root_path}/lib/gcc/arm-none-eabi/%{arm_ver}/include-fixed",
    ]
    if "%{arm_root_path}" == "/usr":
        builtin_includes.append("/usr/lib/arm-none-eabi/include")
        builtin_includes.append("/usr/include/newlib/c++/%{arm_ver}")
        builtin_includes.append("/usr/include/newlib/c++/%{arm_ver}/tr1")
        builtin_includes.append("/usr/include/newlib")
    else:
        builtin_includes.append("%{arm_root_path}/arm-none-eabi/include")

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "armgcc",
        host_system_name = "local",
        target_system_name = "local",
        target_cpu = "unknown",
        target_libc = "unknown",
        compiler = "armgcc",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        # action_configs = action_configs,
        tool_paths = tool_paths,
        features = features,
        cxx_builtin_include_directories = builtin_includes,
    )

arm_gcc_config = rule(
    implementation = _impl,
    attrs = {
        "asm_flags": attr.string_list(),
        "compiler_flags": attr.string_list(default = []),
        "link_flags": attr.string_list(default = []),
    },
    provides = [CcToolchainConfigInfo],
)
