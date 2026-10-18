#!/bin/bash
# Installs the APK on the CI emulator, opens it and records what happens.
set -x
mkdir -p smoke
adb install -r MedBox.apk
PKG=$(aapt2 dump packagename MedBox.apk 2>/dev/null || echo in.medbox.medbox)
echo "package: $PKG" > smoke/info.txt
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 4;  adb exec-out screencap -p > smoke/01_after_4s.png
sleep 8;  adb exec-out screencap -p > smoke/02_after_12s.png
sleep 15; adb exec-out screencap -p > smoke/03_after_27s.png
adb shell dumpsys activity activities | grep -i -E "mResumedActivity|topResumedActivity" >> smoke/info.txt
adb logcat -d > smoke/logcat_full.txt
grep -E "flutter|MEDBOX|AndroidRuntime|FATAL|Exception|Error|ANR" smoke/logcat_full.txt > smoke/logcat_errors.txt || true
exit 0
