#!/bin/sh
ratio="$1"
bus_name="$2"
if [ -z "$bus_name" ]; then exit 0; fi

status=$(busctl --user get-property "$bus_name" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null | awk -F'"' '{print $2}')
if [ "$status" = "Playing" ]; then
    pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s "$bus_name" 2>/dev/null | awk '{print $2}')
    identity=$(busctl --user get-property "$bus_name" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2 Identity 2>/dev/null | awk -F'"' '{print $2}')
    
    if [ -n "$pid" ]; then
        node_id=$(python3 -c "
import json, subprocess, sys
mpris_pid = int('$pid')
identity = '$identity'

ident_norm = identity.lower().replace(' ', '').replace('-', '')
if not ident_norm: sys.exit(0)

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

try:
    mpris_parents = get_parents(mpris_pid)
    data = json.loads(subprocess.check_output(['pw-dump']).decode('utf-8'))
    
    for node in data:
        if node.get('type') == 'PipeWire:Interface:Node':
            props = node.get('info', {}).get('props', {})
            if props.get('media.class') in ('Stream/Output/Audio', 'Audio/Sink'):
                npid = props.get('application.process.id')
                app_name = str(props.get('application.name', '')).lower()
                app_bin = str(props.get('application.process.binary', '')).lower()
                
                app_name_norm = app_name.replace(' ', '').replace('-', '')
                app_bin_norm = app_bin.replace(' ', '').replace('-', '')
                
                if ident_norm in app_bin_norm or ident_norm in app_name_norm:
                    print(node.get('id'))
                    sys.exit(0)
                    
                if npid:
                    try:
                        with open(f'/proc/{npid}/cmdline', 'r') as f:
                            cmdline = f.read().lower().replace('\0', ' ').replace(' ', '').replace('-', '')
                            if ident_norm in cmdline:
                                print(node.get('id'))
                                sys.exit(0)
                    except: pass
                    
                    audio_parents = get_parents(npid)
                    common = mpris_parents.intersection(audio_parents) - {1}
                    if common:
                        print(node.get('id'))
                        sys.exit(0)
except Exception: pass
" 2>/dev/null)
        if [ -n "$node_id" ]; then
            wpctl set-volume "$node_id" "$ratio"
        fi
    fi
fi
