import sys
import subprocess

cmd = sys.argv[1:-1]
output = sys.argv[-1]

ret = subprocess.run(cmd, text=True, capture_output=True)
if ret.returncode == 0:
    with open(output, 'w') as f:
        f.write(ret.stdout)

exit(ret.returncode)
