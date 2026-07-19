import shutil
import sys

deps = ["grim", "slurp", "wl-copy", "jq", "notify-send", "python3", "wpctl", "busctl", "pw-dump", "nmcli", "bluetoothctl", "socat"]
missing = []
for dep in deps:
    if shutil.which(dep) is None:
        missing.append(dep)

if missing:
    print("missing packages: " + ", ".join(missing))
else:
    print("all required packages are installed!")
sys.stdout.flush()
