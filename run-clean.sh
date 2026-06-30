#!/usr/bin/env bash
# Launch the app with the noisy device/OS log spam filtered out.
#
# Two categories of lines drown the useful logs on some devices (notably
# Vivo/iQOO) and are NOT produced by our Dart code — they can't be fixed in
# the app, only hidden:
#   * "avc: denied { ioctl } ... /proc/fas/render"  → Vivo FAS scheduler SELinux denial
#   * "BLASTBufferQueue ... Can't acquire next buffer" → Android SurfaceView back-pressure warning
#   * mali_gralloc / ANDR-VIVO-PERF / BufferQueue* → vendor graphics noise
#
# Usage:
#   ./run-clean.sh            # flutter run, spam stripped from the console
#   ./run-clean.sh --release  # any extra args are forwarded to `flutter run`
set -euo pipefail

FILTER='BLASTBufferQueue|/proc/fas/render|mali_gralloc|ANDR-VIVO-PERF|BufferQueue(Producer|Consumer)|FrameEvents|Invalid base format'

# `--line-buffered` so output streams live instead of buffering; `grep -vE`
# drops every line matching the noise filter.
exec flutter run "$@" 2>&1 | grep --line-buffered -vE "$FILTER"
