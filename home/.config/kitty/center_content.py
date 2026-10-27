"""Toggle left/right padding on the active window so the text area is a fixed
pixel width, centered horizontally.

Usage in kitty.conf:
    map f4 kitten center_content.py 1200

The width is measured once, when toggling on. Resize the window and press the
key twice to recenter.
"""

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.fast_data_types import pt_to_px

DEFAULT_WIDTH_PX = 1200
CENTERED_ATTR = "_center_content_on"


def main(args: list[str]) -> None:
    pass


def _set_side_padding(window, value_pt: float | None) -> None:
    # None restores the padding from kitty.conf
    window.patch_edge_width("padding", "left", value_pt)
    window.patch_edge_width("padding", "right", value_pt)


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: None, target_window_id: int, boss: Boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    tab = window.tabref()

    if getattr(window, CENTERED_ATTR, False):
        _set_side_padding(window, None)
        setattr(window, CENTERED_ATTR, False)
    else:
        width_px = int(args[1]) if len(args) > 1 else DEFAULT_WIDTH_PX
        geometry = window.geometry
        total_px = (
            geometry.right
            - geometry.left
            + window.effective_padding("left")
            + window.effective_padding("right")
        )
        side_px = (total_px - width_px) / 2
        if side_px <= 0:
            return
        px_per_pt = pt_to_px(100, window.os_window_id) / 100
        _set_side_padding(window, side_px / px_per_pt)
        setattr(window, CENTERED_ATTR, True)

    if tab is not None:
        tab.relayout()
