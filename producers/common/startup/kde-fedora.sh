#!/bin/bash
# Native path: kwin_wayland IS the top-level compositor, talking to the display
# daemon directly through its built-in "anland" backend (--anland). There is no
# weston layer and no nested kwin — kwin replaces both. The patched kwin_wayland
# must be installed separately after building the Fedora RPMs with build.sh.
SOCK="${1:-${ANLAND_SOCKET:-/run/display.sock}}"
if [ "${ANLAND_RENDERER:-}" = virgl-vtest ]; then
    echo 'This compositor recipe requires a DRM render node. Use virtio-gpu.' >&2
    exit 1
fi

# Never tear down an existing graphical session automatically.
for process in kwin_wayland plasmashell startplasma-wayland; do
    if pgrep -u "$(id -u)" -f "(^|/)${process}([[:space:]]|$)" >/dev/null; then
        echo "An existing $process session is running; refusing to start another." >&2
        exit 1
    fi
done
[ -S "$SOCK" ] || { echo "Display socket not found: $SOCK" >&2; exit 1; }
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR"; chmod 0700 "$XDG_RUNTIME_DIR"
unset DISPLAY
export ANLAND_SOCKET="$SOCK"
export ANLAND=1
export ANLAND_DRM_DEVICE="${ANLAND_DRM_DEVICE:-/dev/dri/renderD128}"
if [ -c /dev/kgsl-3d0 ] && [ -z "${ANLAND_RENDERER:-}" ]; then
    export ANLAND_SKIP_IMPLICIT_SYNC_WAIT="${ANLAND_SKIP_IMPLICIT_SYNC_WAIT:-1}"
    export MESA_LOADER_DRIVER_OVERRIDE="${MESA_LOADER_DRIVER_OVERRIDE:-kgsl}"
    export GALLIUM_DRIVER="${GALLIUM_DRIVER:-kgsl}" FD_FORCE_KGSL="${FD_FORCE_KGSL:-1}"
fi
export QT_QPA_PLATFORM=wayland
exec dbus-run-session startplasma-wayland
