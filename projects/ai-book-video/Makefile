BOOK ?= $(error BOOK is required. Usage: make <target> BOOK=atomic-habits)
SCRIPTS := scripts
BOOKS := books

.PHONY: init subtitle voice sync validate studio render all clean

init:
	$(SCRIPTS)/init-book.sh $(BOOK)

subtitle:
	$(SCRIPTS)/generate-subtitle.sh $(BOOK)

voice:
	$(SCRIPTS)/generate-voice.sh $(BOOK)

sync:
	$(SCRIPTS)/sync-assets.sh $(BOOK)

validate:
	$(SCRIPTS)/validate-subtitle.sh $(BOOK)

studio: sync
	cd remotion && npm run studio

render: sync
	cd remotion && npx remotion render BookVideo ../$(BOOKS)/$(BOOK)/output/video.mp4

all: subtitle voice sync validate
	@echo "Pipeline complete for $(BOOK)"

clean:
	rm -f $(BOOKS)/$(BOOK)/audio/voiceover.wav
	rm -f $(BOOKS)/$(BOOK)/output/subtitles.srt
	rm -f $(BOOKS)/$(BOOK)/output/section-timing.json
	@echo "Cleaned generated files for $(BOOK)"
