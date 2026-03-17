# Bookie — AI Book Video Pipeline

Automated pipeline that turns books into narrated video content for Book!e ("Book!e Inspires Everyone"), a Vietnamese reading community running for 9+ years.

## Pipeline

Each book goes through a structured production flow, mostly automated via Makefile + bash scripts + Claude Code skills:

1. **Research** — Extract key ideas, angles, and narrative structure from the source book
2. **Storyboard** — Break the narrative into visual sections with scene descriptions
3. **Script** — Write the Vietnamese narration script with timing markers
4. **Voice** — Generate Vietnamese voiceover using viXTTS (self-hosted TTS)
5. **Visuals** — Generate scene images via Google Gemini API, sync to script timing
6. **Assembly** — Compose final video in Remotion with subtitles, BGM, and visual overlays
7. **Publish** — Export long-form video and short-form cuts

## Tech Stack

| Tool | Purpose |
|------|---------|
| Remotion 4.0 | React-based video renderer (composition, subtitles, overlays) |
| viXTTS | Vietnamese text-to-speech, self-hosted |
| Google Gemini API | Scene image generation |
| Claude Code skills | Script writing, storyboard generation, pipeline orchestration |
| Make + bash | Pipeline automation (`make produce BOOK=<slug>`) |
| Git LFS | Media file storage (voiceovers, rendered videos) |

## Produced Videos

| # | Book | Slug |
|---|------|------|
| 1 | Atomic Habits — James Clear | `atomic-habits` |
| 2 | Gia Dinh — Hector Malot | `gia-dinh-hector-malot` |
| 3 | Sa Mon Khong Hai | `sa-mon-khong-hai` |

## About Bookie

Book!e Inspires Everyone is a Vietnamese reading community founded in 2017. The AI book video pipeline is one arm of the community's content production, turning book insights into accessible video format for Vietnamese readers.

## Git LFS

This repo uses Git LFS for media files (~355MB across 9 tracked files — voiceover WAVs, rendered videos, reference audio). Free GitHub LFS has 1GB/month bandwidth. Run `git lfs install` before cloning.

---

All rights reserved.
