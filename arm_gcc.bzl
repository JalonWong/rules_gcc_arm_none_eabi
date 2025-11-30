""" ARM GCC """

load("@rules_gcc_arm_none_eabi//:base.bzl",
    "resolve_labels",
    "get_arm_gcc_version",
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
    version = get_arm_gcc_version(repository_ctx, arm_gcc_path)

    if version:
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
    if "windows" in repository_ctx.os.name:
        redirect_bat = repository_ctx.path(Label("@rules_gcc_arm_none_eabi//toolchain:shell/redirect.bat"))
    else:
        redirect_bat = repository_ctx.path(Label("@rules_gcc_arm_none_eabi//toolchain:shell/redirect.sh"))

    repository_ctx.template(
        "gen.bzl",
        paths["@rules_gcc_arm_none_eabi//toolchain:gen.bzl.tpl"],
        {
            "%{arm_root_path}": arm_gcc_path,
            "%{redirect}": str(redirect_bat),
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
