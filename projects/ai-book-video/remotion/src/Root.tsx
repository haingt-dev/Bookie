import React from "react";
import { Composition, staticFile } from "remotion";
import { loadFont } from "@remotion/google-fonts/Montserrat";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadLocalFont } from "@remotion/fonts";
import { ANIM, VIDEO, SHORT } from "./constants";
import type { VideoConfig } from "./types";
import { BookVideo } from "./compositions/BookVideo";
import { BookShort } from "./compositions/BookShort";
import scenesJson from "./data/scenes.json";

// Load Google Fonts — style first, then options
loadFont("normal", { subsets: ["vietnamese", "latin"], weights: ["400", "700", "800"] });
loadInter("normal", { subsets: ["vietnamese", "latin"], weights: ["400"] });

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
      <Composition
        id="BookShort"
        component={BookShort}
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
    </>
  );
};
