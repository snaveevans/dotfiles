from kitty.boss import Boss
import subprocess
import os
import sys
import json


def get_directories(args: list[str]):
    """Get the list of directories using the 'find' command."""
    expanded_paths = list(map(os.path.expanduser, args))
    find_args = ["find"] + expanded_paths + ["-maxdepth", "1", "-type", "d"]
    result = subprocess.run(find_args, stdout=subprocess.PIPE, text=True)
    directories = result.stdout.strip().split("\n")
    return directories


def select_directory(directories):
    """Use fzf to select a directory."""
    homebrew_prefix = "/opt/homebrew"
    fzf_path = os.path.join(homebrew_prefix, "bin", "fzf")
    result = subprocess.run(
        [fzf_path], input="\n".join(directories), stdout=subprocess.PIPE, text=True
    )
    return result.stdout.strip()


def main(args: list[str]) -> dict[str, str]:
    # Get directories to choose from
    directories = get_directories(args)

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

    existing = boss.match_tabs(f"title:{dir_name}")
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
