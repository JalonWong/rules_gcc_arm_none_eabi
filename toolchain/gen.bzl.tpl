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

def arm_cmd_to_file(ctx, cmd, options, in_file, out_file):
    args = ctx.actions.args()
    args.add("%{redirect_py}")
    args.add(cmd)
    args.add_all(options)
    args.add(in_file.path)
    args.add(out_file.path)

    ctx.actions.run(
        use_default_shell_env = True,
        outputs = [out_file],
        inputs = [in_file],
        arguments = [args],
        executable = "%{python}",
    )

def arm_gen_asm(ctx, input, output):
    arm_cmd_to_file(
        ctx,
        _OBJDUMP,
        ["--disassemble", "--no-show-raw-insn"],
        input,
        output
    )
