#!/usr/bin/env bash
# Chỉnh cấu hình Android sau khi chạy `flutter create`
set -e
G=android/app/build.gradle
K=android/app/build.gradle.kts
if [ -f "$G" ]; then
  sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 26/; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 26/' "$G"
  sed -i 's/compileSdk = flutter.compileSdkVersion/compileSdk = 35/; s/compileSdkVersion flutter.compileSdkVersion/compileSdkVersion 35/' "$G"
  sed -i 's/signingConfig = signingConfigs.debug/signingConfig = signingConfigs.debug\n            minifyEnabled true\n            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"/' "$G"
  grep -n "Sdk\|proguard\|minify" "$G" || true
elif [ -f "$K" ]; then
  sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 26/; s/compileSdk = flutter.compileSdkVersion/compileSdk = 35/' "$K"
  sed -i 's/signingConfig = signingConfigs.getByName("debug")/signingConfig = signingConfigs.getByName("debug")\n            isMinifyEnabled = true\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")/' "$K"
  grep -n "minSdk\|proguard\|Minify" "$K" || true
fi
cp ci/proguard-rules.pro android/app/proguard-rules.pro
sed -i 's/android:label="bien_bao_ai"/android:label="Biển Báo AI"/' android/app/src/main/AndroidManifest.xml
grep -n "android:label" android/app/src/main/AndroidManifest.xml
