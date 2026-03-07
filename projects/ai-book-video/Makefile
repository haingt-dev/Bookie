BOOK ?= $(error BOOK is required. Usage: make <target> BOOK=atomic-habits)
SCRIPTS := scripts
BOOKS := books

.PHONY: init subtitle voice images scenes sync validate studio render render-shorts produce clean

init:
	$(SCRIPTS)/init-book.sh $(BOOK)

subtitle:
	$(SCRIPTS)/generate-subtitle.sh $(BOOK)

voice:
	$(SCRIPTS)/generate-voice.sh $(BOOK)

images:
	$(SCRIPTS)/generate-images.sh $(BOOK)

scenes:
	$(SCRIPTS)/generate-scenes.sh $(BOOK)

sync:
	$(SCRIPTS)/sync-assets.sh $(BOOK)

validate:
	$(SCRIPTS)/validate-subtitle.sh $(BOOK)

studio: sync
	cd remotion && npm run studio

render: sync
	cd remotion && npx remotion render BookVideo ../$(BOOKS)/$(BOOK)/output/video.mp4

render-shorts: sync
	@cd remotion && npx remotion compositions 2>/dev/null | grep '^BookShort-' | while read CID REST; do \
		echo "Rendering $$CID..."; \
		npx remotion render "$$CID" "../$(BOOKS)/$(BOOK)/output/$${CID}.mp4"; \
	done

produce:
	$(SCRIPTS)/produce.sh $(BOOK) $(ARGS)

clean:
	rm -f $(BOOKS)/$(BOOK)/audio/voiceover.wav
	rm -f $(BOOKS)/$(BOOK)/output/subtitles.srt
	rm -f $(BOOKS)/$(BOOK)/output/section-timing.json
	rm -f $(BOOKS)/$(BOOK)/output/voice-timing.json
	rm -f $(BOOKS)/$(BOOK)/scenes/*.jpg $(BOOKS)/$(BOOK)/scenes/*.png
	rm -f remotion/src/data/scenes.json
	rm -f remotion/public/audio remotion/public/scenes remotion/public/subtitles.srt
	@echo "Cleaned generated files for $(BOOK)"
