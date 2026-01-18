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
# 🛠️ Development (Debug APK)
dev:
	@echo "🛠️ Building Debug APK..."
	flutter build apk --debug

# 🚀 Staging (Release APK)
stage:
	@echo "🚀 Building Release APK..."
	flutter build apk --release

# 📦 Production (Release Bundle/AAB)
prod:
	@echo "📦 Building Release Bundle (AAB)..."
	flutter build appbundle --release

# 🧹 Clean
clean:
	flutter clean
