# Pipeline Status

## atomic-habits

> "Dieu ma Atomic Habits khong noi voi ban" — contrarian angle

| # | Step | Status | Output | Notes |
|---|------|--------|--------|-------|
| 1 | Extract notes | Done | notes.md | Key Insights, Quotes, Stories, Competitive Analysis |
| 2 | Create storyboard | Done | storyboard.md | 9 scenes, contrarian narrative arc |
| 3 | Write video | Done | chunks-display.md + chunks.md | 41 chunks, both paired files |
| 4 | Generate voice | Done | voiceover.wav | ~5:35, 9 scenes, 41 pre-split chunks |
| 5 | Generate prompts | Done | image-prompts.md | 9 Gemini prompts with brand style + timing |
| 6 | Generate images | Done | scenes/*.png | 9 scene images via Gemini API |
| 7 | Generate subtitles | Done | subtitles.srt | Balanced line-splitting from chunks-display.md |
| 8 | Render video | Done | video-balanced.mp4 | Visual overlays complete |
| 9 | Write metadata | Pending | metadata.md | `/write-metadata atomic-habits` |
| 10 | Publish | Pending | | YouTube + Facebook |

**Notes**:

- Pipeline verified and ready for next book: pick book → `/produce-video <slug>`
- Knowledge Vault seeded (concepts/habits.md, concepts/identity.md, authors/james-clear.md)
