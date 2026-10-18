#!/bin/bash
# Installs the APK on the CI emulator, opens it and records what happens.
mkdir -p smoke
exec > >(tee smoke/run.log) 2>&1
set -x
which adb
adb devices -l
adb wait-for-device
for i in $(seq 1 60); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
adb shell getprop ro.build.version.sdk
adb install -r MedBox.apk
adb shell pm list packages | grep -i medbox
adb logcat -c
adb shell am start -W -n in.medbox.medbox/.MainActivity
sleep 4;  adb exec-out screencap -p > smoke/01_after_4s.png
sleep 8;  adb exec-out screencap -p > smoke/02_after_12s.png
sleep 15; adb exec-out screencap -p > smoke/03_after_27s.png
adb shell dumpsys activity activities | grep -i -E "ResumedActivity" 
adb logcat -d > smoke/logcat_full.txt
grep -E "flutter|MEDBOX|AndroidRuntime|FATAL|Exception|ANR" smoke/logcat_full.txt > smoke/logcat_errors.txt
ls -la smoke
exit 0
