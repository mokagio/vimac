.PHONY: help bootstrap build test run install screenshot clean

help:
	@echo "Available targets:"
	@echo "  bootstrap   Install bundler gems and CocoaPods deps"
	@echo "  build       Build a Debug .app under build/"
	@echo "  test        Run unit tests (VimacTests target)"
	@echo "  run         Build (if needed) and launch the Debug .app"
	@echo "  install     Build Release and install it to /Applications"
	@echo "  screenshot  Launch app, open Preferences, capture to tmp/screenshots/"
	@echo "  clean       Remove build/ and tmp/"

bootstrap:
	./scripts/bootstrap.sh

build:
	./scripts/build.sh

test:
	./scripts/test.sh

run:
	./scripts/run.sh

install:
	./scripts/install.sh

screenshot:
	./scripts/screenshot.sh

clean:
	rm -rf build tmp
