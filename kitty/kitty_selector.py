from kitty.boss import Boss
import subprocess
import os
import sys
import json

def get_directories(args: list[str]):
    """Get the list of directories using the 'find' command."""
    expanded_paths = list(map(os.path.expanduser, args))
    find_args = ['find'] + expanded_paths + ['-maxdepth', '1', '-type', 'd']
    result = subprocess.run(find_args, stdout=subprocess.PIPE, text=True)
    directories = result.stdout.strip().split('\n')
    return directories

def select_directory(directories):
    """Use fzf to select a directory."""
    homebrew_prefix = "/opt/homebrew"
    fzf_path = os.path.join(homebrew_prefix, 'bin', 'fzf')
    result = subprocess.run([fzf_path], input='\n'.join(directories), stdout=subprocess.PIPE, text=True)
    return result.stdout.strip()

def main(args: list[str]) -> str:
    # Get directories to choose from
    directories = get_directories(args)

    if not directories:
        print("No directories found.")
        sys.exit(1)

    # Let user select a directory using fzf
    selected_directory = select_directory(directories)

    if not selected_directory:
        print("No directory selected.")
        sys.exit(1)

    return selected_directory

def handle_result(args: list[str], selected_directory: str, target_window_id: int, boss: Boss) -> None:
    dir_name = os.path.basename(selected_directory)
    w = boss.window_id_map.get(target_window_id)


    existing = boss.match_tabs(f'title:{dir_name}')
    item = next(existing, None)

    if item is not None:
        boss.call_remote_control(w, ('focus-tab', f'--match=id:{item.id}'))
    else:
        boss.call_remote_control(w, ('launch', '--type=tab', '--cwd', selected_directory, '--tab-title', dir_name))
