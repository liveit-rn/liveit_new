.PHONY: dev stage prod clean help

help:
	@echo "🤖 LiveIt Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make dev       - Build Debug APK (faster, for dev)"
	@echo "  make stage     - Build Release APK (optimized, for manual testing)"
	@echo "  make prod      - Build Release AAB (for Play Store)"
	@echo "  make clean     - Clean build artifacts"
	@echo ""

# 🛠️ Development (Debug APK)
dev:
	@echo "🛠️ Building Debug APK..."
	cd android && bundle exec fastlane build_debug_apk

# 🚀 Staging (Release APK)
stage:
	@echo "🚀 Building Release APK..."
	cd android && bundle exec fastlane build_release_apk

# 📦 Production (Release Bundle/AAB)
prod:
	@echo "📦 Building Release Bundle (AAB)..."
	cd android && bundle exec fastlane build_bundle

# 🧹 Clean
clean:
	cd android && ./gradlew clean
	flutter clean
