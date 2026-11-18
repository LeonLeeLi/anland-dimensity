#!/usr/bin/env bash
set -euo pipefail

die() { printf 'anland-virgl: %s\n' "$*" >&2; exit 1; }
usage() {
    printf '%s\n' 'Usage:' \
        '  anland-virgl.sh --vtest SOCKET -- COMMAND [ARGS...]' \
        '  anland-virgl.sh --drm RENDER_NODE -- COMMAND [ARGS...]'
}

case ${1:-} in --help|-h) usage; exit 0 ;; esac
[[ $# -ge 4 && $3 == -- ]] || { usage >&2; exit 2; }
mode=$1
device=$2
shift 3

unset MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER FD_FORCE_KGSL TURNIP_KMD
unset LIBGL_ALWAYS_SOFTWARE LIBGL_ALWAYS_INDIRECT
unset FD_DEV_FEATURES MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE

case $mode in
    --vtest)
        [[ -S $device ]] || die "vtest socket not found: $device"
        device=$(realpath -e -- "$device")
        export ANLAND_RENDERER=virgl-vtest
        export VTEST_SOCKET_NAME="$device" GALLIUM_DRIVER=virpipe LIBGL_ALWAYS_SOFTWARE=1
        export ANLAND_SKIP_IMPLICIT_SYNC_WAIT=0
        unset ANLAND_DRM_DEVICE XWAYLAND_GBM_DEVICE KWIN_RENDER_NODES WLR_RENDER_DRM_DEVICE
        ;;
    --drm)
        [[ -c $device && -r $device && -w $device ]] || die "cannot access DRM render node: $device"
        device=$(realpath -e -- "$device")
        major_minor=$(stat -Lc '%t:%T' -- "$device")
        sysdev=$(printf '/sys/dev/char/%d:%d' "0x${major_minor%:*}" "0x${major_minor#*:}")
        [[ $(basename -- "$(readlink -f -- "$sysdev")") == renderD* ]] ||
            die "expected a DRM render node: $device"
        [[ $(basename -- "$(readlink -f -- "$sysdev/device/driver")") == virtio_gpu ]] ||
            die "expected a virtio-gpu render node: $device"
        export ANLAND_RENDERER=virgl-drm
        export ANLAND_DRM_DEVICE="$device" XWAYLAND_GBM_DEVICE="$device"
        export KWIN_RENDER_NODES="$device" WLR_RENDER_DRM_DEVICE="$device"
        export ANLAND_SKIP_IMPLICIT_SYNC_WAIT=0
        unset VTEST_SOCKET_NAME
        ;;
    *)
        usage >&2; exit 2
        ;;
esac

exec "$@"
