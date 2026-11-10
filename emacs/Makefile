# Shortcuts.  `make help' lists them.
.PHONY: help setup update doctor test test-offline compile disk slim bench clean

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

compile:   ## byte-compile the config (faster startup); `make clean' undoes it
	emacs --batch --init-directory $(CURDIR) -l early-init.el -l init.el \
	  --eval '(my/compile-config)'

disk:      ## show disk usage
	emacs --batch --init-directory $(CURDIR) -l early-init.el -l init.el \
	  --eval '(princ (my/disk-usage))'

slim:      ## free disk: orphan packages, old native code, old snapshots
	emacs --batch --init-directory $(CURDIR) -l early-init.el -l init.el \
	  --eval '(my/clean)'

bench:     ## time how long the config takes to load
	emacs --batch --init-directory $(CURDIR) -l early-init.el -l init.el \
	  --eval '(my/benchmark-startup)'

clean:     ## delete installed packages, caches, compiled config (reinstall on next start; keeps var/)
	rm -rf elpa eln-cache tree-sitter package-quickstart.el package-quickstart.elc lisp/*.elc
