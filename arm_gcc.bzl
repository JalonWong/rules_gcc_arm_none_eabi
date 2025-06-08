""" ARM GCC """

load("@rules_gcc_arm_none_eabi//:base.bzl",
    "resolve_labels",
    "find_python",
    "find_toolchain_path",
    "print_info",
    "print_warn",
    "get_ext",
)

def _impl(repository_ctx):
    paths = resolve_labels(repository_ctx, [
        "@rules_gcc_arm_none_eabi//toolchain:BUILD",
        "@rules_gcc_arm_none_eabi//toolchain:toolchain.bzl",
        "@rules_gcc_arm_none_eabi//toolchain:config.bzl.tpl",
        "@rules_gcc_arm_none_eabi//toolchain:gen.bzl.tpl",
    ])

    repository_ctx.symlink(paths["@rules_gcc_arm_none_eabi//toolchain:BUILD"], "BUILD")
    repository_ctx.symlink(paths["@rules_gcc_arm_none_eabi//toolchain:toolchain.bzl"], "toolchain.bzl")

    arm_gcc_path = find_toolchain_path(repository_ctx, "arm-none-eabi-gcc")

    optional_cflags = []
    ver_py = repository_ctx.path(Label("@rules_gcc_arm_none_eabi//toolchain:arm_gcc_version.py"))

    python = find_python(repository_ctx)
    # print([python, ver_py, arm_gcc_path])
    result = repository_ctx.execute([python, ver_py, arm_gcc_path])

    if result.return_code == 0:
        version = result.stdout.strip()
        print_info("ARM GCC version: {}".format(version))
    else:
        print_warn("ARM GCC compiler not found in {}".format(arm_gcc_path))

    if int(version.split(".")[0]) >= 12:
        inner_link_flags = "-Wl,-no-warn-rwx-segments"
    else:
        inner_link_flags = ""

    work_dir = str(repository_ctx.path("../../execroot/_main"))

    repository_ctx.template(
        "config.bzl",
        paths["@rules_gcc_arm_none_eabi//toolchain:config.bzl.tpl"],
        {
            "%{arm_root_path}": arm_gcc_path,
            "%{arm_ver}": version,
            "%{work_dir}": work_dir,
            "%{inner_link_flags}": inner_link_flags,
            "%{wrapper_ext}": get_ext(repository_ctx),
        },
    )

    redirect_py = repository_ctx.path(Label("@rules_gcc_arm_none_eabi//toolchain:redirect.py"))
    repository_ctx.template(
        "gen.bzl",
        paths["@rules_gcc_arm_none_eabi//toolchain:gen.bzl.tpl"],
        {
            "%{arm_root_path}": arm_gcc_path,
            "%{redirect_py}": str(redirect_py),
            "%{python}": python,
        },
    )

arm_repository = repository_rule(
    implementation = _impl,
    configure = True,
)

def _toolchains_ext_impl(_module_ctx):
    # Generate repo of toolchains
    arm_repository(name = "arm_gcc_")

toolchains_ext = module_extension(
    implementation = _toolchains_ext_impl,
)
