#!/usr/bin/env bash
# Silence the noisy device/graphics log tags AT THE SOURCE so they never reach
# `flutter run` — this cleans Android Studio's *Run* tab (which has no filter
# UI), not just Logcat.
#
# `setprop log.tag.<TAG> SILENT` tells Android's logging system to drop all
# output for that tag. Effects are immediate and last until the device reboots
# (re-run this after a reboot). No root required.
#
# Usage:  ./silence-device-logs.sh           (uses the only connected device)
#         ./silence-device-logs.sh <serial>  (target a specific device)
set -euo pipefail

TARGET=()
if [ "${1:-}" != "" ]; then TARGET=(-s "$1"); fi

# The graphics/perf spam this app triggers on Vivo/iQOO + Mali devices.
TAGS=(
  BLASTBufferQueue      # "Can't acquire next buffer" flood
  BufferQueueProducer
  BufferQueueConsumer
  BufferQueue
  mali_gralloc          # "Unsupported format" gralloc noise
  ANDR-VIVO-PERF        # Vivo perf HAL "tryGetService failed"
  FrameEvents
  OpenGLRenderer
)

for t in "${TAGS[@]}"; do
  adb "${TARGET[@]}" shell setprop "log.tag.$t" SILENT
  echo "silenced log.tag.$t"
done

echo
echo "Done. Restart the app (or hot-restart) and the Run tab should be clean."
echo "NOTE: the kernel SELinux 'avc denied /proc/fas/render' (binder) lines are"
echo "audit logs that setprop can't silence; if any remain, use the Logcat tab."
