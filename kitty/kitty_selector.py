from kitty.boss import Boss
import subprocess
import os
import sys
import json
import shutil


def find_fzf():
    """Find fzf executable in PATH or common locations."""
    # On macOS, apps launched from Dock/Launcher don't inherit shell PATH
    # So we need to check common locations first, then try PATH
    
    # Common locations to check first (especially important on macOS)
    common_locations = [
        "/opt/homebrew/bin/fzf",  # Homebrew on Apple Silicon
        "/usr/local/bin/fzf",     # Homebrew on Intel
        "/usr/bin/fzf",           # System package manager
        os.path.expanduser("~/.local/bin/fzf"),  # Local install
        "/snap/bin/fzf",          # Snap package (Linux)
    ]
    
    # Check common locations first
    for path in common_locations:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    
    # Try to find fzf in PATH as fallback
    fzf_path = shutil.which("fzf")
    if fzf_path:
        return fzf_path
    
    # Try to source shell profile and get PATH
    # This helps when apps are launched from Dock on macOS
    try:
        # Try to get PATH from user's shell profile
        shell_profiles = [
            os.path.expanduser("~/.zshrc"),
            os.path.expanduser("~/.bashrc"),
            os.path.expanduser("~/.bash_profile"),
            os.path.expanduser("~/.profile"),
        ]
        
        for profile in shell_profiles:
            if os.path.exists(profile):
                # Source the profile and get PATH
                result = subprocess.run(
                    ["bash", "-c", f"source {profile} && echo $PATH"],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    extended_path = result.stdout.strip()
                    # Split PATH and check each directory
                    for path_dir in extended_path.split(":"):
                        fzf_candidate = os.path.join(path_dir, "fzf")
                        if os.path.isfile(fzf_candidate) and os.access(fzf_candidate, os.X_OK):
                            return fzf_candidate
                break
    except (subprocess.TimeoutExpired, Exception):
        # If shell sourcing fails, continue with other methods
        pass
    
    # If still not found, return None
    return None


def get_directories(args: list[str]):
    """Get the list of directories using the 'find' command."""
    expanded_paths = list(map(os.path.expanduser, args))
    find_args = ["find"] + expanded_paths + ["-maxdepth", "1", "-type", "d"]
    result = subprocess.run(find_args, stdout=subprocess.PIPE, text=True)
    directories = result.stdout.strip().split("\n")
    return directories


def select_directory(directories):
    """Use fzf to select a directory."""
    fzf_path = find_fzf()
    if not fzf_path:
        raise FileNotFoundError("fzf not found in PATH or common locations")
    
    result = subprocess.run(
        [fzf_path], input="\n".join(directories), stdout=subprocess.PIPE, text=True
    )
    return result.stdout.strip()


def select_open_tab():
    result = subprocess.run(["kitty", "@", "ls"], capture_output=True, text=True)

    # Parse the JSON output
    data = json.loads(result.stdout)

    # Extract the list of tabs
    tabs = []
    for session in data:
        for tab in session["tabs"]:
            tabs.append(tab["title"])
    
    fzf_path = find_fzf()
    if not fzf_path:
        return {"status": "error", "message": "fzf not found in PATH or common locations"}
    
    result = subprocess.run(
        [fzf_path], input="\n".join(tabs), stdout=subprocess.PIPE, text=True
    )
    selected_tab = result.stdout.strip()
    if not selected_tab:
        return {"status": "error", "message": "No open tab selected."}
    return {"status": "success", "selected_directory": selected_tab}


def main(args: list[str]) -> dict[str, str]:
    kitten_name, mode, *dirs = args
    # Get directories to choose from
    directories = get_directories(dirs)

    # return {
    #     "status": "testing",
    #     "message": mode,
    #     "selected_directory": "ccloud-ui",
    # }

    if mode == "open":
        return select_open_tab()

    if not directories:
        return {"status": "error", "message": "No directories found."}

    # Let user select a directory using fzf
    selected_directory = select_directory(directories)

    if not selected_directory:
        return {"status": "error", "message": "no directory selected"}

    return {"status": "success", "selected_directory": selected_directory}


def handle_result(
    args: list[str], value: dict[str, str], target_window_id: int, boss: Boss
) -> None:
    w = boss.window_id_map.get(target_window_id)
    # w.paste_text(
    #     f'status: {value.get("status")} message: {value.get("message")} selected_directory: {value.get("selected_directory")}'
    # )
    # return
    if value["status"] == "error":
        # w.paste_text(f"Error: {value['message']}")
        return
    # elif value.get("status") == "success":
    #     w.paste_text(f"Selected directory: {value['selected_directory']}")
    #     return
    # else:
    #     w.paste_text(f"Unknown error: {value}")
    #     return

    selected_directory = value.get("selected_directory")
    if selected_directory is None:
        return
    dir_name = os.path.basename(selected_directory)

    # w.paste_text(
    #     f"Selected directory: {selected_directory} ---- directory name: {dir_name}"
    # )
    # return

    existing = boss.match_tabs(f"title:^{dir_name}$")
    item = next(existing, None)

    # w.paste_text(f"dir_name: {dir_name} ---- item: {item}")
    # return

    if item is not None:
        boss.call_remote_control(w, ("focus-tab", f"--match=id:{item.id}"))
    else:
        boss.call_remote_control(
            w,
            (
                "launch",
                "--type=tab",
                "--cwd",
                selected_directory,
                "--tab-title",
                dir_name,
            ),
        )
