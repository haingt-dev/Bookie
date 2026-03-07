import type { ChapterInfo, SceneData } from "../types";

/**
 * Detect chapter boundaries from scene labels using prefix heuristic.
 * Groups consecutive scenes that share the same "chapter prefix".
 *
 * Logic: extract the first significant word/phrase from each label.
 * When the prefix changes, a new chapter starts.
 *
 * Examples:
 *   HOOK, CONTEXT → each is its own chapter
 *   ĐIỂM MÙ 1: ..., BẰNG CHỨNG, ĐIỂM MÙ 2: ... → "ĐIỂM MÙ" groups together
 */
export function detectChapters(scenes: SceneData[]): ChapterInfo[] {
  if (scenes.length === 0) return [];

  const chapters: ChapterInfo[] = [];
  let currentTitle = normalizeLabel(scenes[0].label);
  let startIndex = 0;

  for (let i = 1; i < scenes.length; i++) {
    const title = normalizeLabel(scenes[i].label);
    if (title !== currentTitle) {
      chapters.push({ title: currentTitle, startIndex, endIndex: i - 1 });
      currentTitle = title;
      startIndex = i;
    }
  }
  chapters.push({ title: currentTitle, startIndex, endIndex: scenes.length - 1 });

  return chapters;
}

/**
 * Normalize a scene label to its chapter prefix.
 * Strips numbered suffixes (e.g., "ĐIỂM MÙ 1: ..." → "ĐIỂM MÙ")
 * and collapses to the core identifier.
 */
function normalizeLabel(label?: string): string {
  if (!label) return "";
  // Remove everything after a colon or number sequence
  return label.replace(/\s*\d+\s*[:.].*$/, "").trim();
}

/**
 * Use explicit chapters if provided and valid, otherwise auto-detect.
 */
export function resolveChapters(
  scenes: SceneData[],
  explicitChapters?: ChapterInfo[],
): ChapterInfo[] {
  if (!explicitChapters || explicitChapters.length === 0) {
    return detectChapters(scenes);
  }
  // Validate: every scene index must be covered by some chapter
  const covered = new Set<number>();
  for (const ch of explicitChapters) {
    for (let i = ch.startIndex; i <= ch.endIndex; i++) {
      covered.add(i);
    }
  }
  if (scenes.every((_, i) => covered.has(i))) {
    return explicitChapters;
  }
  return detectChapters(scenes);
}

/**
 * Check if a scene index is a chapter boundary (first scene of a new chapter).
 */
export function isChapterBoundary(
  sceneIndex: number,
  chapters: ChapterInfo[],
): boolean {
  return chapters.some(
    (ch) => ch.startIndex === sceneIndex && sceneIndex > 0,
  );
}
