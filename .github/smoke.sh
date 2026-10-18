#!/bin/bash
# Installs the APK on the CI emulator, opens it, taps through the tabs and
# records screenshots + logs.
mkdir -p smoke
exec > >(tee smoke/run.log) 2>&1
set -x
adb wait-for-device
for i in $(seq 1 60); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
sleep 20   # let the launcher settle so it doesn't show "not responding"
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS
adb shell wm size
adb shell wm density
adb install -r MedBox.apk
adb logcat -c
adb shell am start -W -n in.medbox.medbox/.MainActivity
shot() { adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null; adb exec-out screencap -p > "smoke/$1.png"; }
sleep 2;  shot 01_splash
sleep 10; shot 02_home
adb shell input tap 540 1250; sleep 5; shot 02b_detail
adb shell input keyevent 4; sleep 3
adb shell input tap 336 2022;  sleep 4; shot 03_box
adb shell input tap 744 2022;  sleep 4; shot 04_alerts
adb shell input tap 942 2022;  sleep 4; shot 05_settings
adb shell input tap 120 2022;  sleep 4; shot 06_home_again
adb shell input tap 540 1946;  sleep 5; shot 07_scan
adb shell dumpsys activity activities | grep -i -E "ResumedActivity"
adb logcat -d > smoke/logcat_full.txt
grep -E "MEDBOX|AndroidRuntime|FATAL|ANR in|flutter.*(Exception|Error)" smoke/logcat_full.txt > smoke/logcat_errors.txt
ls -la smoke
exit 0
