""" Generate """

_OBJCOPY = "%{arm_root_path}/bin/arm-none-eabi-objcopy"
_OBJDUMP = "%{arm_root_path}/bin/arm-none-eabi-objdump"

def arm_gen_bin(ctx, input, output, inputs):
    ctx.actions.run(
        outputs = [output],
        inputs = [input] + inputs,
        arguments = ["-O", "binary", "-S", input.path, output.path],
        executable = _OBJCOPY,
    )

def arm_gen_hex(ctx, input, output, inputs):
    ctx.actions.run(
        outputs = [output],
        inputs = [input] + inputs,
        arguments = ["-O", "ihex", input.path, output.path],
        executable = _OBJCOPY,
    )

def arm_cmd_to_file(ctx, cmd, args, in_file, out_file, use_default_shell_env):
    arguments = ctx.actions.args()
    arguments.add(out_file.path)
    arguments.add(cmd)
    for arg in args:
        if arg == "$(input)":
            arguments.add(in_file.path)
        else:
            arguments.add(arg)

    ctx.actions.run(
        use_default_shell_env = use_default_shell_env,
        outputs = [out_file],
        inputs = [in_file],
        arguments = [arguments],
        executable = "%{redirect}",
    )

def arm_gen_asm(ctx, input, output):
    arm_cmd_to_file(
        ctx,
        _OBJDUMP,
        ["--disassemble", "--no-show-raw-insn", input.path],
        input,
        output,
        False,
    )
