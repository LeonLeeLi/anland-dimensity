#!/bin/bash
# Native path: kwin_wayland IS the top-level compositor, talking to the display
# daemon directly through its built-in "anland" backend (--anland). There is no
# weston layer and no nested kwin — kwin replaces both. The patched kwin_wayland
# must be installed (see build.sh, which builds the .deb with the anland
# backend baked in).
SOCK="${1:-${ANLAND_SOCKET:-/run/display.sock}}"

for process in kwin_wayland plasmashell startplasma-wayland; do
    if pgrep -u "$(id -u)" -f "(^|/)${process}([[:space:]]|$)" >/dev/null; then
        echo "An existing $process session is running; refusing to start another." >&2
        exit 1
    fi
done
[ -S "$SOCK" ] || { echo "Display socket not found: $SOCK" >&2; exit 1; }
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR"; chmod 0700 "$XDG_RUNTIME_DIR"
unset DISPLAY WAYLAND_DISPLAY WAYLAND_SOCKET
export ANLAND_SOCKET="$SOCK"
export ANLAND=1
if [ -c /dev/kgsl-3d0 ] && [ -z "${ANLAND_RENDERER:-}" ]; then
    export MESA_LOADER_DRIVER_OVERRIDE="${MESA_LOADER_DRIVER_OVERRIDE:-kgsl}"
    export GALLIUM_DRIVER="${GALLIUM_DRIVER:-kgsl}"
    export FD_FORCE_KGSL="${FD_FORCE_KGSL:-1}"
    # KGSL synchronizes implicitly when sampling client DMA-BUFs.
    export ANLAND_SKIP_IMPLICIT_SYNC_WAIT="${ANLAND_SKIP_IMPLICIT_SYNC_WAIT:-1}"
fi
export QT_QPA_PLATFORM=wayland
# Tell xdg-desktop-portal this is a KDE session, so it loads the kde backend and
# kde-portals.conf. Without this, portal detection falls back to the gtk backend,
# which is X11-only and crashes ("cannot open display"), hanging portal startup
# for 120s and leaving the workspace black. Required for the camera portal too.
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
export XDG_SESSION_TYPE=wayland
exec dbus-run-session startplasma-wayland
