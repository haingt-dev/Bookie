BOOK ?=
SCRIPTS := scripts
BOOKS := books

# Assert BOOK is set (call from targets that need it)
need-book = $(if $(BOOK),,$(error BOOK is required. Usage: make <target> BOOK=<slug>))

.PHONY: start stop status init subtitle voice images scenes sync validate studio render render-shorts produce clean

start:
	$(SCRIPTS)/vixtts-server.sh start

stop:
	$(SCRIPTS)/vixtts-server.sh stop

status:
	$(SCRIPTS)/vixtts-server.sh status

init:
	$(need-book)
	$(SCRIPTS)/init-book.sh $(BOOK)

subtitle:
	$(need-book)
	$(SCRIPTS)/generate-subtitle.sh $(BOOK)

voice:
	$(need-book)
	$(SCRIPTS)/generate-voice.sh $(BOOK)

images:
	$(need-book)
	$(SCRIPTS)/generate-images.sh $(BOOK)

scenes:
	$(need-book)
	$(SCRIPTS)/generate-scenes.sh $(BOOK)

sync:
	$(need-book)
	$(SCRIPTS)/sync-assets.sh $(BOOK)

validate:
	$(need-book)
	$(SCRIPTS)/validate-subtitle.sh $(BOOK)

studio: sync
	cd remotion && npm run studio

render: sync
	cd remotion && npx remotion render BookVideo ../$(BOOKS)/$(BOOK)/output/video.mp4 --audio-bitrate 320k

render-shorts: sync
	@cd remotion && npx remotion compositions 2>/dev/null | grep '^BookShort-' | while read CID REST; do \
		echo "Rendering $$CID..."; \
		npx remotion render "$$CID" "../$(BOOKS)/$(BOOK)/output/$${CID}.mp4"; \
	done

produce:
	$(need-book)
	$(SCRIPTS)/produce.sh $(BOOK) $(ARGS)

clean:
	$(need-book)
	rm -f $(BOOKS)/$(BOOK)/audio/voiceover.wav
	rm -f $(BOOKS)/$(BOOK)/output/subtitles.srt
	rm -f $(BOOKS)/$(BOOK)/output/section-timing.json
	rm -f $(BOOKS)/$(BOOK)/output/voice-timing.json
	rm -f $(BOOKS)/$(BOOK)/scenes/*.jpg $(BOOKS)/$(BOOK)/scenes/*.png
	rm -f remotion/src/data/scenes.json
	rm -f remotion/public/audio remotion/public/scenes remotion/public/subtitles.srt
	@echo "Cleaned generated files for $(BOOK)"
