import React from "react";
import { Composition, staticFile } from "remotion";
import { loadFont } from "@remotion/google-fonts/Montserrat";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadLora } from "@remotion/google-fonts/Lora";
import { loadFont as loadLocalFont } from "@remotion/fonts";
import { ANIM, VIDEO, SHORT } from "./constants";
import type { VideoConfig } from "./types";
import { BookVideo } from "./compositions/BookVideo";
import { BookShort } from "./compositions/BookShort";
import scenesJson from "./data/scenes.json";

// Load Google Fonts — style first, then options
loadFont("normal", { subsets: ["vietnamese", "latin"], weights: ["400", "700", "800"] });
loadInter("normal", { subsets: ["vietnamese", "latin"], weights: ["400"] });
loadLora("normal", { subsets: ["vietnamese", "latin"], weights: ["400", "700"] });

// Load local Be Vietnam Pro for subtitles
loadLocalFont({
  family: "Be Vietnam Pro",
  url: staticFile("fonts/BeVietnamPro-Regular.ttf"),
  weight: "400",
});

const config = scenesJson as VideoConfig;

function calcTotalFrames(cfg: VideoConfig, fps: number): number {
  const intro = cfg.intro.duration * fps;
  const scenes = cfg.scenes.reduce((sum, s) => sum + s.duration * fps, 0);
  const overlaps = Math.max(0, cfg.scenes.length - 1) * ANIM.fadeFrames;
  const outro = cfg.outro.duration * fps;
  return intro + scenes - overlaps + outro;
}

/** Calculate voice start time for a given scene index (cumulative scene duration) */
function calcVoiceStartMs(cfg: VideoConfig, sceneIndex: number): number {
  let ms = 0;
  for (let i = 0; i < sceneIndex; i++) {
    ms += cfg.scenes[i].duration * 1000;
  }
  return ms;
}

/** Extract shorts from scenes marked isShort */
function extractShorts(cfg: VideoConfig) {
  return cfg.scenes
    .map((s, i) => ({ ...s, index: i }))
    .filter((s) => s.isShort)
    .map((s, n) => ({
      id: `BookShort-${String(n + 1).padStart(2, "0")}`,
      startScene: s.index,
      endScene: s.index,
      voiceStartMs: calcVoiceStartMs(cfg, s.index),
      durationFrames: Math.round(s.duration * SHORT.fps),
      label: s.label ?? `Short ${n + 1}`,
    }));
}

const shorts = extractShorts(config);

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="BookVideo"
        component={BookVideo}
        durationInFrames={calcTotalFrames(config, VIDEO.fps)}
        fps={VIDEO.fps}
        width={VIDEO.width}
        height={VIDEO.height}
        defaultProps={{ config }}
      />
      {shorts.length > 0
        ? shorts.map((short) => (
            <Composition
              key={short.id}
              id={short.id}
              component={BookShort as React.FC}
              durationInFrames={short.durationFrames}
              fps={SHORT.fps}
              width={SHORT.width}
              height={SHORT.height}
              defaultProps={{
                config,
                startScene: short.startScene,
                endScene: short.endScene,
                voiceStartMs: short.voiceStartMs,
              }}
            />
          ))
        : (
            <Composition
              id="BookShort"
              component={BookShort as React.FC}
              durationInFrames={30 * SHORT.fps}
              fps={SHORT.fps}
              width={SHORT.width}
              height={SHORT.height}
              defaultProps={{
                config,
                startScene: 0,
                endScene: 0,
                voiceStartMs: 0,
              }}
            />
          )}
    </>
  );
};
