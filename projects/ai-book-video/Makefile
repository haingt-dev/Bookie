BOOK ?= $(error BOOK is required. Usage: make <target> BOOK=atomic-habits)
SCRIPTS := scripts
BOOKS := books

.PHONY: init subtitle voice scenes sync validate studio render all clean

init:
	$(SCRIPTS)/init-book.sh $(BOOK)

subtitle:
	$(SCRIPTS)/generate-subtitle.sh $(BOOK)

voice:
	$(SCRIPTS)/generate-voice.sh $(BOOK)

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

all: voice subtitle scenes sync validate
	@echo "Pipeline complete for $(BOOK)"

clean:
	rm -f $(BOOKS)/$(BOOK)/audio/voiceover.wav
	rm -f $(BOOKS)/$(BOOK)/output/subtitles.srt
	rm -f $(BOOKS)/$(BOOK)/output/section-timing.json
	rm -f $(BOOKS)/$(BOOK)/output/voice-timing.json
	rm -f $(BOOKS)/$(BOOK)/scenes/*.jpg $(BOOKS)/$(BOOK)/scenes/*.png
	rm -f remotion/src/data/scenes.json
	rm -f remotion/public/audio remotion/public/scenes remotion/public/subtitles.srt
	@echo "Cleaned generated files for $(BOOK)"
