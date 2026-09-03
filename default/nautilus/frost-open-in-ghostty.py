# Package-owned Nautilus extension: an "Abrir no Ghostty" entry on a folder and
# on the folder background. It shells out to the fixed Frost terminal wrapper
# with a working directory and nothing else — no command is built from user
# input. Installed to /usr/share/nautilus-python/extensions/.

import os
import subprocess

import gi

gi.require_version("Nautilus", "4.0")
from gi.repository import GObject, Nautilus  # noqa: E402

# First existing wrapper wins. frost-terminal layers the runtime theme over the
# shipped Ghostty defaults; the bare binary is the fallback.
_TERMINALS = ("/usr/lib/frost/frost-terminal", "/usr/bin/ghostty")


def _terminal() -> str | None:
    for path in _TERMINALS:
        if os.path.exists(path):
            return path
    return None


def _local_directory(file_info) -> str | None:
    if file_info.get_uri_scheme() != "file":
        return None
    location = file_info.get_location()
    path = location.get_path() if location is not None else None
    if path and os.path.isdir(path):
        return path
    return None


class FrostOpenInGhostty(GObject.GObject, Nautilus.MenuProvider):
    def _open(self, path: str) -> None:
        terminal = _terminal()
        if terminal is None:
            return
        subprocess.Popen(
            [terminal, "--working-directory=" + path],
            cwd=path,
            start_new_session=True,
        )

    def _menu_item(self, name: str, path: str) -> Nautilus.MenuItem:
        item = Nautilus.MenuItem(
            name=name,
            label="Abrir no Ghostty",
            tip="Abrir um terminal Ghostty nesta pasta",
        )
        item.connect("activate", lambda _item: self._open(path))
        return item

    def get_background_items(self, current_folder):
        path = _local_directory(current_folder)
        if path is None or _terminal() is None:
            return []
        return [self._menu_item("FrostOpenInGhostty::background", path)]

    def get_file_items(self, files):
        if len(files) != 1:
            return []
        path = _local_directory(files[0])
        if path is None or _terminal() is None:
            return []
        return [self._menu_item("FrostOpenInGhostty::file", path)]
