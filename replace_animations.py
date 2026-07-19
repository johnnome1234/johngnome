import sys
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
shell_path = os.path.join(script_dir, 'shell.qml')

with open(shell_path, 'r') as f:
    content = f.read()

replacements = [
    ('Behavior on color {', 'Behavior on color { enabled: Settings.animationEnabled;'),
    ('Behavior on scale {', 'Behavior on scale { enabled: Settings.animationEnabled;'),
    ('Behavior on width {', 'Behavior on width { enabled: Settings.animationEnabled;'),
    ('Behavior on opacity {', 'Behavior on opacity { enabled: Settings.animationEnabled;'),
    ('Behavior on implicitHeight {', 'Behavior on implicitHeight { enabled: Settings.animationEnabled;'),
    ('Behavior on height {', 'Behavior on height { enabled: Settings.animationEnabled;'),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(shell_path, 'w') as f:
    f.write(content)
