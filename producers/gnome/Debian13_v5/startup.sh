#!/bin/bash
SOCK="${1:-${ANLAND_SOCKET:-/run/display.sock}}"
if [ "${ANLAND_RENDERER:-}" = virgl-vtest ]; then
    echo 'This compositor recipe requires a DRM render node. Use virtio-gpu.' >&2
    exit 1
fi
# Never terminate an existing graphical session implicitly.
for process_name in gnome-shell gnome-session mutter; do
    if pgrep -u "$(id -u)" -f "(^|/)${process_name}([[:space:]]|$)" >/dev/null; then
        echo "An existing $process_name session is running; refusing to start another." >&2
        exit 1
    fi
done
[ -S "$SOCK" ] || { echo "Display socket not found: $SOCK" >&2; exit 1; }
export ANLAND=1
export ANLAND_SOCKET="$SOCK"
export QT_QPA_PLATFORM=wayland XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_DESKTOP=gnome XDG_SESSION_TYPE=wayland GNOME_SHELL_SESSION_MODE=gnome
export WAYLAND_DISPLAY=wayland-anland GNOME_WAYLAND_DISPLAY=wayland-anland
export ANLAND_DRM_DEVICE="${ANLAND_DRM_DEVICE:-/dev/dri/renderD128}"
if [ -c /dev/kgsl-3d0 ] && [ -z "${ANLAND_RENDERER:-}" ]; then
    export MESA_LOADER_DRIVER_OVERRIDE="${MESA_LOADER_DRIVER_OVERRIDE:-kgsl}"
    export GALLIUM_DRIVER="${GALLIUM_DRIVER:-freedreno}" FD_FORCE_KGSL="${FD_FORCE_KGSL:-1}"
    export TURNIP_KMD="${TURNIP_KMD:-kgsl}"
fi
export XDG_RUNTIME_DIR=/run/user/$(id -u)
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chown $(id -un):$(id -gn) $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix
exec gnome-session
