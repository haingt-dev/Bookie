import type { SubtitleEntry } from "../types";

export function timeToMs(time: string): number {
  const [h, m, rest] = time.split(":");
  const [s, ms] = rest.split(",");
  return (
    parseInt(h) * 3600000 +
    parseInt(m) * 60000 +
    parseInt(s) * 1000 +
    parseInt(ms)
  );
}

export function parseSRT(text: string): SubtitleEntry[] {
  const entries: SubtitleEntry[] = [];
  const blocks = text.trim().split(/\n\n+/);

  for (const block of blocks) {
    const lines = block.split("\n");
    if (lines.length < 3) continue;

    const index = parseInt(lines[0]);
    if (isNaN(index)) continue;

    const timeMatch = lines[1].match(
      /(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})/
    );
    if (!timeMatch) continue;

    entries.push({
      index,
      startMs: timeToMs(timeMatch[1]),
      endMs: timeToMs(timeMatch[2]),
      text: lines.slice(2).join("\n"),
    });
  }

  return entries;
}
