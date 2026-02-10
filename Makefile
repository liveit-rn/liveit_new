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

dev:
	fvm flutter run -t lib/main_dev.dart

# 🛠️ Development (Debug APK)
build-dev:
	@echo "🛠️ Building Debug APK..."
	fvm flutter build apk --debug

# 🚀 Staging (Release APK - for manual testing on device)
build-stage:
	@echo "🚀 Building Release APK (Production config)..."
	fvm flutter build apk --release -t lib/main_prod.dart

# 📦 Production (Release Bundle/AAB)
build-prod:
	@echo "📦 Building Release Bundle (AAB)..."
	fvm flutter build appbundle --release

# 🧹 Clean
clean:
	flutter clean
