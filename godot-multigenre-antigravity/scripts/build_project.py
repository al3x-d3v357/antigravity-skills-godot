"""
Godot 4 Automation and CLI Tool for Antigravity IDE
Suporta o binario local em D:\\epicgms\GodotEngine
"""

import os
import sys
import argparse
import subprocess
import glob
import shutil

DEFAULT_GODOT_DIR = r"D:\\epicgms\GodotEngine"

def find_godot_binary(custom_path=None):
    if custom_path and os.path.isfile(custom_path):
        return custom_path
    
    if os.path.isdir(DEFAULT_GODOT_DIR):
        console_binaries = sorted(glob.glob(os.path.join(DEFAULT_GODOT_DIR, "*console.exe")), reverse=True)
        if console_binaries:
            return console_binaries[0]
        
        gui_binaries = sorted(glob.glob(os.path.join(DEFAULT_GODOT_DIR, "*.exe")), reverse=True)
        if gui_binaries:
            return gui_binaries[0]
            
    for cmd in ["godot", "godot4", "godot_console"]:
        found = shutil.which(cmd)
        if found:
            return found
            
    return None

def main():
    parser = argparse.ArgumentParser(description="Godot 4 automation runner for Antigravity IDE")
    parser.add_argument("--project-path", "-p", default=".", help="Path to Godot project (folder with project.godot)")
    parser.add_argument("--godot-bin", "-b", default=None, help="Explicit path to Godot executable")
    parser.add_argument("--headless", action="store_true", help="Run in headless mode")
    parser.add_argument("--check-only", action="store_true", help="Import assets and check syntax without rendering")
    parser.add_argument("--run-scene", "-s", default=None, help="Specific scene to run (e.g. res://scenes/arena.tscn)")
    parser.add_argument("--run", "-r", action="store_true", help="Launch the main project scene")
    parser.add_argument("--export-preset", "-e", default=None, help="Export preset name")
    parser.add_argument("--export-path", default=None, help="Export output path")
    
    args = parser.parse_args()
    
    binary = find_godot_binary(args.godot_bin)
    if not binary:
        print("[-] Erro: Executavel do Godot 4 nao encontrado em D:\\epicgms\GodotEngine ou PATH.")
        sys.exit(1)
        
    print(f"[+] Usando Godot em: {binary}")
    project_godot = os.path.join(args.project_path, "project.godot")
    if not os.path.isfile(project_godot):
        print(f"[!] Aviso: 'project.godot' nao foi encontrado em '{args.project_path}'.")
        
    cmd = [binary, "--path", os.path.abspath(args.project_path)]
    
    if args.headless or args.check_only:
        cmd.append("--headless")
        
    if args.check_only:
        cmd.extend(["--import", "--quit"])
    elif args.export_preset:
        if not args.export_path:
            print("[-] Erro: --export-path e obrigatorio com --export-preset.")
            sys.exit(1)
        cmd.extend(["--export-release", args.export_preset, os.path.abspath(args.export_path)])
    elif args.run_scene:
        cmd.append(args.run_scene)
    elif args.run:
        pass
    else:
        cmd.extend(["--import", "--quit"])
        
    cmd_display = " ".join(cmd)
    print(f"[>] Executando: {cmd_display}")
    proc = subprocess.run(cmd)
    sys.exit(proc.returncode)

if __name__ == "__main__":
    main()
