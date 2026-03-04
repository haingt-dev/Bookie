export interface SceneData {
  id: string;
  image: string;
  duration: number; // seconds
}

export interface VideoConfig {
  title: string;
  bookSlug: string;
  hasBgm: boolean;
  subtitleAdjustMs?: number;
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
