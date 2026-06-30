# Silence the noisy device/graphics log tags AT THE SOURCE so they never reach
# `flutter run` — this cleans Android Studio's *Run* tab (which has no filter
# UI), not just Logcat.
#
# `setprop log.tag.<TAG> SILENT` tells Android's logging system to drop all
# output for that tag. Effects are immediate and last until the device reboots
# (re-run this after a reboot). No root required.
#
# Usage:  ./silence-device-logs.ps1        (uses the only connected device)
#         ./silence-device-logs.ps1 <serial>   (target a specific device)

$ErrorActionPreference = 'Stop'
$serial = if ($args.Count -ge 1) { $args[0] } else { $null }
$target = if ($serial) { @('-s', $serial) } else { @() }

# The graphics/perf spam this app triggers on Vivo/iQOO + Mali devices.
$tags = @(
  'BLASTBufferQueue',     # "Can't acquire next buffer" flood
  'BufferQueueProducer',
  'BufferQueueConsumer',
  'BufferQueue',
  'mali_gralloc',         # "Unsupported format" gralloc noise
  'ANDR-VIVO-PERF',       # Vivo perf HAL "tryGetService failed"
  'FrameEvents',
  'OpenGLRenderer'
)

foreach ($t in $tags) {
  & adb @target shell setprop "log.tag.$t" SILENT
  Write-Output "silenced log.tag.$t"
}

Write-Output ""
Write-Output "Done. Restart the app (or hot-restart) and the Run tab should be clean."
Write-Output "NOTE: the kernel SELinux 'avc denied /proc/fas/render' (binder) lines are"
Write-Output "audit logs that setprop can't silence; if any remain, use the Logcat tab."
