# Skill: Mobile Release Strategy

**Context:** Strategi build dan rilis untuk aplikasi Mobile (React Native) yang "Boring" tetapi powerful.
**Goal:** 1-Command Build & Release.

## 1. Philosophy: "Push Button, Get APK"

Jangan manual buka Xcode/Android Studio untuk build production. Gunakan **Fastlane** sebagai engine, dan **Makefile** sebagai interface sederhana.

## 2. Tools Recommendation

### A. Fastlane (The Engine)

Industry standard untuk automasi mobile. Menangani:

- Increment Version Code/Name
- Certificate pipeline (Match)
- Build Android (Gradle) & iOS (Xcode build)
- Upload ke Store (Play Store / TestFlight)

### B. Makefile (The Interface)

Wrapper sederhana supaya developer tidak perlu menghafal command fastlane yang panjang.

## 3. Implementation Guide

### Step 1: Init Fastlane

Di folder `liveit-rn` (root mobile project):

```bash
cd android && fastlane init
cd ../ios && fastlane init
```

### Step 2: Configure `Fastfile`

Contoh konfigurasi "Boring" di `android/fastlane/Fastfile`:

```ruby
default_platform(:android)

platform :android do
  desc "Build APK for easy distribution"
  lane :build_apk do
    # 1. Pastikan bersih
    gradle(task: "clean")

    # 2. Build Release
    gradle(
      task: "assemble",
      build_type: "Release"
    )

    # 3. (Optional) Upload ke Firebase App Distribution / Slack
    # firebase_app_distribution(...)
  end
end
```

### Step 3: Create `Makefile`

Buat file bernama `Makefile` di root project mobile Anda (`liveit-rn/Makefile`):

```makefile
.PHONY: android ios

# 🤖 Android Builds
android:
	@echo "🤖 Building Android APK..."
	cd android && bundle exec fastlane build_apk

# 🍎 iOS Builds
ios:
	@echo "🍎 Building iOS IPA..."
	cd ios && bundle exec fastlane build_ipa

# 🧹 Clean
clean:
	cd android && ./gradlew clean
	cd ios && xcodebuild clean
	rm -rf node_modules
```

## 4. Usage

Sekarang developer cukup ketik:

- `make android` -> Jadi APK di folder output.
- `make ios` -> Jadi IPA.

## Why this is better?

- **Reproducible:** Tidak tergantung config manual di laptop developer.
- **Documented in Code:** Langkah build tersimpan di `Fastfile`, bukan di kepala developer.
- **Simple:** Cukup ingat `make android`.
