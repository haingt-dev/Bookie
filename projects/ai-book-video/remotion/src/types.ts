// Video metadata — book/author/angle for Intro and downstream consumers
export interface VideoMeta {
  bookTitle: string;
  author: string;
  angle: string;
  template?: string;
}

// Per-scene visual direction overrides for Ken Burns
export type PanDirection = "left" | "right" | "up" | "down" | "none";
export type ZoomDirection = "in" | "out" | "none";

export interface SceneData {
  id: string;
  image: string;
  duration: number; // seconds
  label?: string;
  layout?: LayoutMode; // override even/odd alternation
  panDir?: PanDirection; // override Ken Burns pan direction
  zoomDir?: ZoomDirection; // override Ken Burns zoom direction
  isShort?: boolean; // marked for shorts extraction
}

export interface VideoConfig {
  title: string;
  bookSlug: string;
  hasBgm: boolean;
  subtitleAdjustMs?: number;
  meta?: VideoMeta;
  chapters?: ChapterInfo[];
  intro: {
    duration: number; // seconds
  };
  outro: {
    duration: number; // seconds
    ctaText: string;
    nextBookTitle: string;
  };
  scenes: SceneData[];
}

export interface SubtitleEntry {
  index: number;
  startMs: number;
  endMs: number;
  text: string;
}

export type LayoutMode = "bleed" | "framed";

export interface ChapterInfo {
  title: string;
  startIndex: number;
  endIndex: number;
}
