.PHONY: help clean get-version bump-version release changelog docs

help:
	@echo "make help         -- show this help"
	@echo "make clean        -- clean leftovers and build files"
	@echo "make get-version  -- get current version"
	@echo "make bump-version -- bump version"
	@echo "make release      -- create github release"
	@echo "make changelog    -- update changelog"
	@echo "make docs         -- build documentation"


clean:
	./scripts/clean.sh $(MAKEFLAGS)

get-version:
	./scripts/get-version.sh

bump-version:
	./scripts/bump-version.sh $(MAKEFLAGS)

release:
	./scripts/release.sh $(MAKEFLAGS)

changelog:
	./scripts/changelog.sh $(MAKEFLAGS)

docs:
	./scripts/docs.sh $(MAKEFLAGS)
