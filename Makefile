WORKFLOW := build.yml
OUT_DIR  := ~/Desktop/urchin_firmware/$(shell date +%Y%m%d-%H%M%S)

# macOS: Nice! Nano nRF52840 mounts as NICENANO in bootloader mode.
# Override if your system mounts it differently.
BOOT_LEFT  ?= /Volumes/NICENANO
BOOT_RIGHT ?= /Volumes/NICENANO

.PHONY: help build status download flash-left flash-right

help:
	@echo "Urchin ZMK — zmk studio no-dongle workflow"
	@echo ""
	@echo "  make build        Trigger GitHub Actions build"
	@echo "  make status       Show recent build runs"
	@echo "  make download     Download latest firmware artifacts → $(OUT_DIR)/"
	@echo "  make flash-left   Copy left UF2 to mounted bootloader drive"
	@echo "  make flash-right  Copy right UF2 to mounted bootloader drive"
	@echo ""
	@echo "Keymap:  config/urchin.keymap"
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. Edit config/urchin.keymap"
	@echo "  2. make build"
	@echo "  3. make download   (once Actions completes)"
	@echo "  4. Double-tap reset on each half to enter bootloader"
	@echo "     make flash-left && make flash-right"
	@echo ""
	@echo "Artifacts: urchin_left (USB central + ZMK Studio), urchin_right"

build:
	gh workflow run $(WORKFLOW)
	@echo "✓ Build triggered — run 'make status' to check progress"

status:
	gh run list --workflow=$(WORKFLOW) --limit=5

download:
	@mkdir -p $(OUT_DIR)
	$(eval RUN_ID := $(shell gh run list --workflow=$(WORKFLOW) --status=success --limit=1 --json databaseId -q '.[0].databaseId'))
	@test -n "$(RUN_ID)" || (echo "Error: no successful run found" && exit 1)
	@mkdir -p $(OUT_DIR)/_tmp
	gh run download $(RUN_ID) --dir $(OUT_DIR)/_tmp
	@find $(OUT_DIR)/_tmp -name '*.uf2' -exec mv {} $(OUT_DIR)/ \;
	@rm -rf $(OUT_DIR)/_tmp
	@echo "✓ Artifacts downloaded to $(OUT_DIR)"

flash-left:
	@test -d "$(BOOT_LEFT)" || (echo "Error: $(BOOT_LEFT) not mounted. Double-tap reset on left half first." && exit 1)
	cp $(OUT_DIR)/urchin_left.uf2 "$(BOOT_LEFT)/urchin_left.uf2"
	@echo "✓ Left half flashed"

flash-right:
	@test -d "$(BOOT_RIGHT)" || (echo "Error: $(BOOT_RIGHT) not mounted. Double-tap reset on right half first." && exit 1)
	cp $(OUT_DIR)/urchin_right.uf2 "$(BOOT_RIGHT)/urchin_right.uf2"
	@echo "✓ Right half flashed"

flash-reset:
	@test -d "$(BOOT_RESET)" || (echo "Error: $(BOOT_RESET) not mounted. Double-tap reset on reset device first." && exit 1)
	cp $(OUT_DIR)/settings_reset.uf2 "$(BOOT_RESET)/settings_reset.uf2"
	@echo "✓ Reset device flashed"