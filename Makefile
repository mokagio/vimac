.PHONY: help bootstrap build test run screenshot clean

help:
	@echo "Available targets:"
	@echo "  bootstrap   Install bundler gems, CocoaPods, Carthage deps"
	@echo "  build       Build an unsigned Debug .app under build/"
	@echo "  test        Run unit tests (VimacTests target)"
	@echo "  run         Build (if needed) and launch the Debug .app"
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

screenshot:
	./scripts/screenshot.sh

clean:
	rm -rf build tmp
