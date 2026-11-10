# Shortcuts.  `make help' lists them.
.PHONY: help setup update doctor test test-offline compile clean

help:      ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

setup:     ## full setup (same as ./setup.sh)
	./setup.sh

update:    ## pull + snapshot + upgrade packages
	./setup.sh --update

doctor:    ## health report
	./setup.sh --doctor

test:      ## load the config and run the smoke tests
	./test/run.sh

test-offline: ## same, without trying to download packages
	OFFLINE=1 ./test/run.sh

compile:   ## byte-compile lisp/ to check for mistakes (then cleans up)
	emacs --batch --init-directory $(CURDIR) -l early-init.el -l init.el \
	  -f batch-byte-compile lisp/*.el; rm -f lisp/*.elc

clean:     ## delete installed packages + caches (reinstall on next start; keeps history and snapshots in var/)
	rm -rf elpa eln-cache tree-sitter package-quickstart.el
