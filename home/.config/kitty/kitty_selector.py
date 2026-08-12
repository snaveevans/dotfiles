from kitty.boss import Boss
import subprocess
import os
import sys
import json
import re
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


def find_wt():
    """Find the wt executable, which Dock-launched Kitty cannot see via PATH."""
    common_locations = [
        os.path.expanduser("~/.local/bin/wt"),
        os.path.expanduser("~/bin/wt"),
        "/usr/local/bin/wt",
    ]

    for path in common_locations:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    return shutil.which("wt")


def find_claude():
    """Find the claude executable, same reasoning as find_wt() - it lives
    under ~/.local/bin, which Dock-launched Kitty's kittens don't see."""
    common_locations = [
        os.path.expanduser("~/.local/bin/claude"),
        os.path.expanduser("~/bin/claude"),
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
    ]

    for path in common_locations:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    return shutil.which("claude")


def select_worktree(scope_current_repo: bool = False) -> dict[str, str]:
    """Pick a git worktree and return its path plus the tab title to use."""
    wt_path = find_wt()
    if not wt_path:
        return {"status": "error", "message": "wt not found in PATH or common locations"}

    fzf_path = find_fzf()
    if not fzf_path:
        return {"status": "error", "message": "fzf not found in PATH or common locations"}

    # Kitty sets a kitten's cwd to that of the program running in the window
    # that invoked it (see docs/kittens/custom.rst), so `wt`'s own repo
    # scoping - based on its cwd - already lands on the right repo here.
    list_args = [wt_path, "list"]
    if not scope_current_repo:
        list_args.append("--all")
    list_args.append("--format=fzf")

    listing = subprocess.run(
        list_args,
        stdout=subprocess.PIPE,
        text=True,
    )
    rows = [row for row in listing.stdout.split("\n") if row.strip()]
    if not rows:
        message = "No worktrees found for this repo." if scope_current_repo else "No worktrees found."
        return {"status": "error", "message": message}

    prompt = "worktree (repo)> " if scope_current_repo else "worktree> "

    # wt emits "display<TAB>tab title<TAB>path"; fzf only shows the first field.
    result = subprocess.run(
        [fzf_path, "+m", "--delimiter=\t", "--with-nth=1", f"--prompt={prompt}"],
        input="\n".join(rows),
        stdout=subprocess.PIPE,
        text=True,
    )
    selected = result.stdout.strip()
    if not selected:
        return {"status": "error", "message": "no worktree selected"}

    fields = selected.split("\t")
    if len(fields) < 3:
        return {"status": "error", "message": "unexpected wt output"}

    return {"status": "success", "selected_directory": fields[2], "tab_title": fields[1]}


def prompt_line(message: str, prompt: str = "> ") -> str | None:
    """Ask for a line of free text using kitty's bundled `ask` kitten.

    Runs as a plain subprocess (same trick as calling fzf from here): the
    kitten prints its JSON result to stdout instead of going through kitty's
    map-triggered handle_result dispatch, which we don't need.
    """
    result = subprocess.run(
        ["kitty", "+kitten", "ask", "--type=line", f"--message={message}", f"--prompt={prompt}"],
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return None

    # `ask` prints the --message text as a plain bold line on stdout before
    # its (pretty-printed, multi-line) JSON result, so the JSON object is
    # only ever the tail of stdout starting at its first brace.
    try:
        json_start = result.stdout.index("{")
        response = json.loads(result.stdout[json_start:]).get("response")
    except (ValueError, AttributeError):
        return None

    return response.strip() if response else None


def create_worktree() -> dict[str, str]:
    """Prompt for a branch name and base ref, create a worktree for it, and hand back its path."""
    wt_path = find_wt()
    if not wt_path:
        return {"status": "error", "message": "wt not found in PATH or common locations"}

    branch = prompt_line("New worktree branch name", prompt="branch> ")
    if not branch:
        return {"status": "error", "message": "no branch name entered"}

    # Optional: cancelling or leaving this blank falls through to `wt new`'s
    # own default (origin's HEAD branch), so it's not treated as an abort.
    base_ref = prompt_line("Base branch (blank for default)", prompt="from> ")

    new_args = [wt_path, "new", branch]
    if base_ref:
        new_args += ["--from", base_ref]

    created = subprocess.run(
        new_args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    dest = created.stdout.strip()
    if created.returncode != 0 or not dest:
        message = created.stderr.strip() or "wt new failed"
        return {"status": "error", "message": message}

    # Look up the repo-qualified title `wt` assigned this worktree (same
    # "repo:slug" convention select_worktree() reads) so the new tab and any
    # later re-pick of it share one title instead of drifting apart.
    listing = subprocess.run(
        [wt_path, "list", dest, "--format=fzf"],
        stdout=subprocess.PIPE,
        text=True,
    )
    row = next((r for r in listing.stdout.split("\n") if r.strip()), "")
    fields = row.split("\t")
    tab_title = fields[1] if len(fields) >= 3 else os.path.basename(dest)

    return {"status": "success", "selected_directory": dest, "tab_title": tab_title}


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


_AGENT_STATE_PRIORITY = {"blocked": 0, "failed": 1, "working": 2, "done": 3, "idle": 4}
_AGENT_STATE_LABELS = {
    "working": "● working",
    "blocked": "⏸ needs input",
    "failed": "✗ failed",
    "done": "✓ done",
    "idle": "○ idle",
}
# `claude agents --json` reports background jobs and live interactive
# sessions with different vocabularies - a background job's `state` maps
# straight onto the labels above, but an interactive session only has
# `status` (busy/waiting/idle/shell), which needs translating.
_INTERACTIVE_STATUS_TO_STATE = {
    "busy": "working",
    "waiting": "blocked",
    "idle": "idle",
    "shell": "idle",
}


def load_agent_jobs() -> list[tuple[str, str]]:
    """Return (cwd, state) for every active Claude Code session.

    Uses `claude agents --json`, the CLI's own scriptable session list -
    documented via `claude agents --help` as "for scripting; does not
    require a TTY". This covers both background jobs and interactive
    sessions running live in a terminal; reading ~/.claude/jobs directly (an
    earlier version of this) missed interactive sessions entirely, since a
    plain `claude` session sitting in a Kitty tab has no job directory - only
    background jobs get one.
    """
    claude_path = find_claude()
    if not claude_path:
        return []

    try:
        result = subprocess.run(
            [claude_path, "agents", "--all", "--json"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        sessions = json.loads(result.stdout)
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return []

    jobs = []

    for session in sessions:
        cwd = session.get("cwd")
        if not cwd:
            continue

        if session.get("kind") == "background":
            state = session.get("state") or ""
        else:
            state = _INTERACTIVE_STATUS_TO_STATE.get(session.get("status"), "")

        if state:
            jobs.append((cwd, state))

    return jobs


def container_roots() -> set[str]:
    """Directories whose immediate children are separate projects.

    A job several directories under one of these belongs to whichever
    project it's actually in, not to the container itself - unlike a
    worktree or repo checkout, where working several directories deep is
    still the same project. These are only valid as exact-match anchors.
    """
    roots = set()
    for var, default in (("WT_WORKSPACE", "~/workspace"), ("WT_ROOT", "~/worktrees")):
        roots.add(os.path.expanduser(os.environ.get(var, default)).rstrip("/"))
    return roots


def agent_status_for_paths(paths: list[str], jobs: list[tuple[str, str]]) -> str | None:
    """Status label for jobs whose cwd is at or under any of `paths`.

    A path exactly at $HOME is dropped before matching: a window sitting bare
    at home isn't "inside" any project, and treating it as an anchor would
    match nearly every job on the machine, since every job's cwd is a
    descendant of home. This matters for split-pane tabs - one pane parked at
    home is enough to poison the whole tab's status if it isn't excluded.

    A path that's a container root (see `container_roots`) only matches a
    job whose cwd is exactly that path, not one somewhere underneath it -
    otherwise a tab sitting at ~/workspace would pick up every job running
    in every repo under it, the same failure mode $HOME has, just one level
    down and only for jobs at the container root itself, not descendants.
    """
    home = os.path.expanduser("~").rstrip("/")
    containers = container_roots()
    anchors = [p.rstrip("/") for p in paths if p and p.rstrip("/") != home]

    best = None
    count = 0

    for cwd, state in jobs:
        matched = any(
            cwd == anchor or (anchor not in containers and cwd.startswith(anchor + "/"))
            for anchor in anchors
        )
        if not matched:
            continue
        count += 1
        if state in _AGENT_STATE_PRIORITY and (
            best is None or _AGENT_STATE_PRIORITY[state] < _AGENT_STATE_PRIORITY[best]
        ):
            best = state

    if best is None:
        return None

    label = _AGENT_STATE_LABELS[best]
    return f"{label} ×{count}" if count > 1 else label


def agent_status_for(path: str, jobs: list[tuple[str, str]]) -> str | None:
    """Status label for jobs whose cwd is at or under `path`, or None."""
    return agent_status_for_paths([path], jobs)


def select_open_tab():
    result = subprocess.run(["kitty", "@", "ls"], capture_output=True, text=True)

    # Parse the JSON output
    data = json.loads(result.stdout)
    jobs = load_agent_jobs()

    # Extract the list of tabs, annotated with agent status when a job's cwd
    # falls inside one of the tab's windows. A tab can be a split with several
    # windows at different cwds, so every window is matched, not just the
    # first - otherwise whichever window happens to come first decides the
    # whole tab's status.
    entries = []
    for session in data:
        for tab in session["tabs"]:
            title = tab["title"]
            cwds = [window.get("cwd") for window in tab.get("windows", [])]
            status = agent_status_for_paths(cwds, jobs)
            entries.append((title, status))

    # Titles vary a lot in length, so without padding the status column
    # lands in a different place on every row and the list reads as noise.
    width = max((len(title) for title, _ in entries), default=0)
    rows = [
        (f"{title:<{width}}  {status}" if status else title, title)
        for title, status in entries
    ]

    fzf_path = find_fzf()
    if not fzf_path:
        return {"status": "error", "message": "fzf not found in PATH or common locations"}

    # fzf shows only the display column; the title (field 2) is the value.
    lines = [f"{display}\t{title}" for display, title in rows]
    result = subprocess.run(
        [fzf_path, "--delimiter=\t", "--with-nth=1"],
        input="\n".join(lines),
        stdout=subprocess.PIPE,
        text=True,
    )
    selected = result.stdout.strip()
    if not selected:
        return {"status": "error", "message": "No open tab selected."}
    selected_tab = selected.split("\t")[-1]
    return {"status": "success", "selected_directory": selected_tab}


def main(args: list[str]) -> dict[str, str]:
    kitten_name, mode, *dirs = args

    if mode == "open":
        return select_open_tab()

    if mode == "worktree":
        return select_worktree()

    if mode == "worktree-repo":
        return select_worktree(scope_current_repo=True)

    if mode == "worktree-new":
        return create_worktree()

    # Get directories to choose from
    directories = get_directories(dirs)

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
        if len(args) > 1 and args[1] == "worktree-new":
            boss.show_error("Create worktree", value.get("message", "unknown error"))
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

    # Worktrees need a repo-qualified title because two checkouts of different
    # repos can share a basename.
    dir_name = value.get("tab_title") or os.path.basename(selected_directory)

    # Check if a tab with this title already exists
    try:
        existing_tabs = [
            tab
            for tab in boss.match_tabs(f"title:^{re.escape(dir_name)}$")
            if tab.effective_title == dir_name
        ]
        if existing_tabs:
            # Focus the existing tab
            boss.call_remote_control(w, ("focus-tab", f"--match=id:{existing_tabs[0].id}"))
        else:
            # Create a new tab
            boss.call_remote_control(
                w,
                (
                    "launch",
                    "--type=tab",
                    f"--cwd={selected_directory}",
                    f"--tab-title={dir_name}",
                ),
            )
    except Exception as e:
        # If matching fails, just create a new tab
        boss.call_remote_control(
            w,
            (
                "launch",
                "--type=tab",
                f"--cwd={selected_directory}",
                f"--tab-title={dir_name}",
            ),
        )
