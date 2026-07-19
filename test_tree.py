import subprocess, json

def get_parents(start_pid):
    parents = set([int(start_pid)])
    current = int(start_pid)
    while current > 1:
        try:
            ppid_str = subprocess.check_output(['ps', '-o', 'ppid=', '-p', str(current)]).decode('utf-8').strip()
            if not ppid_str: break
            ppid = int(ppid_str)
            if ppid <= 1: break
            parents.add(ppid)
            current = ppid
        except: break
    return parents

# Let's test FreeTube (instance2) which we saw was PID 8734 (xdg-dbus-proxy)
mpris_parents = get_parents(8734)

data = json.loads(subprocess.check_output(['pw-dump']).decode('utf-8'))
for node in data:
    if node.get('type') == 'PipeWire:Interface:Node':
        props = node.get('info', {}).get('props', {})
        if props.get('media.class') in ('Stream/Output/Audio', 'Audio/Sink'):
            npid = props.get('application.process.id')
            if npid:
                audio_parents = get_parents(npid)
                common = mpris_parents.intersection(audio_parents)
                # Filter out systemd, etc. Usually any common parent is good if we just exclude PID 1.
                # Since get_parents already breaks if ppid <= 1, we don't even have PID 1 in the sets!
                # Wait, if get_parents breaks at ppid <= 1, then PID 1 is NEVER in the set!
                print(f"Node: {node.get('id')} App: {props.get('application.name')}")
                print(f"  Common Parents: {common}")
