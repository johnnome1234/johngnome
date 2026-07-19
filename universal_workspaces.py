#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import time

def detect_wm():
    if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
        return 'hyprland'
    if os.environ.get('SWAYSOCK'):
        return 'sway'
    
    desktop = os.environ.get('XDG_CURRENT_DESKTOP', '').lower()
    session = os.environ.get('XDG_SESSION_DESKTOP', '').lower()
    
    if 'gnome' in desktop or 'gnome' in session:
        return 'gnome'
        
    try:
        if subprocess.run(['mmsg', '--version'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            return 'mango'
    except Exception:
        pass
        
    return 'mango' # Fallback to mango as default since it's the native environment here

def format_output(active_ws, tags_list):
    # active_ws: int
    # tags_list: list of dicts: {'index': int, 'client_count': int}
    tags = []
    for tag in tags_list:
        tags.append({
            "index": tag['index'],
            "is_active": tag['index'] == active_ws,
            "client_count": tag['client_count']
        })
    
    output = {
        "monitors": [
            {
                "active_tags": [active_ws],
                "tags": tags
            }
        ]
    }
    print(json.dumps(output), flush=True)

def watch_mango():
    process = subprocess.Popen(['mmsg', 'watch', 'all-monitors'], stdout=subprocess.PIPE, text=True)
    for line in iter(process.stdout.readline, ''):
        if line:
            print(line.strip(), flush=True)

def dispatch_mango(ws):
    subprocess.run(['mmsg', 'dispatch', f'view,{ws},0'])

def watch_hyprland():
    def get_state():
        try:
            active_out = subprocess.check_output(['hyprctl', 'activeworkspace', '-j']).decode('utf-8')
            active_ws = json.loads(active_out).get('id', 1)
            
            workspaces_out = subprocess.check_output(['hyprctl', 'workspaces', '-j']).decode('utf-8')
            workspaces = json.loads(workspaces_out)
            
            tags_list = []
            for i in range(1, 10):
                count = sum(1 for w in workspaces if w.get('id') == i and w.get('windows') > 0)
                tags_list.append({'index': i, 'client_count': 1 if count > 0 else 0})
                
            format_output(active_ws, tags_list)
        except Exception:
            pass

    get_state()
    signature = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    if not signature:
        return
        
    sock_path = f"/tmp/hypr/{signature}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"{os.environ.get('XDG_RUNTIME_DIR')}/hypr/{signature}/.socket2.sock"
        
    try:
        process = subprocess.Popen(['socat', '-U', '-', f'UNIX-CONNECT:{sock_path}'], stdout=subprocess.PIPE, text=True)
        for line in iter(process.stdout.readline, ''):
            if line and ('workspace>>' in line or 'createworkspace>>' in line or 'destroyworkspace>>' in line):
                get_state()
    except Exception:
        while True:
            get_state()
            time.sleep(1)

def dispatch_hyprland(ws):
    subprocess.run(['hyprctl', 'dispatch', 'workspace', str(ws)])

def watch_sway():
    def get_state():
        try:
            workspaces_out = subprocess.check_output(['swaymsg', '-t', 'get_workspaces']).decode('utf-8')
            workspaces = json.loads(workspaces_out)
            
            active_ws = 1
            tags_list = []
            
            for i in range(1, 10):
                tags_list.append({'index': i, 'client_count': 0})
                
            for w in workspaces:
                num = w.get('num', -1)
                if num > 0 and num <= 9:
                    if w.get('focused'):
                        active_ws = num
                    tags_list[num-1]['client_count'] = 1 if w.get('visible') or w.get('focused') else 0
                    
            format_output(active_ws, tags_list)
        except Exception:
            pass

    get_state()
    try:
        process = subprocess.Popen(['swaymsg', '-t', 'subscribe', '-m', '["workspace"]'], stdout=subprocess.PIPE, text=True)
        for line in iter(process.stdout.readline, ''):
            if line:
                get_state()
    except Exception:
        while True:
            get_state()
            time.sleep(1)

def dispatch_sway(ws):
    subprocess.run(['swaymsg', 'workspace', str(ws)])

def watch_gnome():
    def get_state(desktop_str):
        try:
            active_ws = int(desktop_str) + 1
            tags_list = [{'index': i, 'client_count': 0} for i in range(1, 10)]
            tags_list[active_ws - 1]['client_count'] = 1
            format_output(active_ws, tags_list)
        except Exception:
            pass
            
    try:
        # Initial state
        out = subprocess.check_output(['xprop', '-root', '_NET_CURRENT_DESKTOP']).decode('utf-8')
        val = out.split('=')[-1].strip()
        get_state(val)
        
        # Watch
        process = subprocess.Popen(['xprop', '-root', '-spy', '_NET_CURRENT_DESKTOP'], stdout=subprocess.PIPE, text=True)
        for line in iter(process.stdout.readline, ''):
            if line and '=' in line:
                val = line.split('=')[-1].strip()
                get_state(val)
    except Exception:
        while True:
            time.sleep(1)

def dispatch_gnome(ws):
    try:
        subprocess.run(['wmctrl', '-s', str(int(ws)-1)])
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        return
        
    action = sys.argv[1]
    wm = detect_wm()
    
    if action == 'watch':
        if wm == 'hyprland':
            watch_hyprland()
        elif wm == 'sway':
            watch_sway()
        elif wm == 'gnome':
            watch_gnome()
        else:
            watch_mango()
            
    elif action == 'dispatch':
        if len(sys.argv) < 3:
            return
        ws = sys.argv[2]
        
        if wm == 'hyprland':
            dispatch_hyprland(ws)
        elif wm == 'sway':
            dispatch_sway(ws)
        elif wm == 'gnome':
            dispatch_gnome(ws)
        else:
            dispatch_mango(ws)

if __name__ == "__main__":
    main()
