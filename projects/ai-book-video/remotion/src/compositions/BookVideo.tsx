import React, { useMemo } from "react";
import {
  AbsoluteFill,
  Audio,
  interpolate,
  Sequence,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, BGM_AMBIENT, BGM_VOLUME } from "../constants";
import type { LayoutMode, VideoConfig } from "../types";
import { isChapterBoundary, resolveChapters } from "../utils/chapters";
import { AmbientParticles } from "./components/AmbientParticles";
import { BrandBar } from "./components/BrandBar";
import { CornerAccents } from "./components/CornerAccents";
import { GrainOverlay } from "./components/GrainOverlay";
import { Intro } from "./components/Intro";
import { LightLeak } from "./components/LightLeak";
import { Outro } from "./components/Outro";
import { SceneSlide } from "./components/SceneSlide";
import { SceneTitleOverlay } from "./components/SceneTitleOverlay";
import { Subtitle } from "./components/Subtitle";
import { Vignette } from "./components/Vignette";
import { WaveformDecor } from "./components/WaveformDecor";

/** Determine which scene is active at a given absolute frame */
function getActiveSceneIndex(
  frame: number,
  introFrames: number,
  sceneEntries: { from: number; duration: number }[],
): number {
  const contentFrame = frame - introFrames;
  if (contentFrame < 0) return 0;

  for (let i = 0; i < sceneEntries.length; i++) {
    const localFrom = sceneEntries[i].from - introFrames;
    const localEnd = localFrom + sceneEntries[i].duration;
    if (contentFrame < localEnd) return i;
  }
  return sceneEntries.length - 1;
}

export const BookVideo: React.FC<{ config: VideoConfig }> = ({ config }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const introFrames = config.intro.duration * fps;
  const outroFrames = config.outro.duration * fps;
  const overlapFrames = ANIM.fadeFrames;

  // Prefer explicit chapters from config, fall back to auto-detection
  const chapters = useMemo(
    () => resolveChapters(config.scenes, config.chapters),
    [config.scenes, config.chapters],
  );

  // Calculate scene start frames with cross-dissolve overlap
  let currentFrame = introFrames;
  const sceneEntries = config.scenes.map((scene, i) => {
    const from = currentFrame;
    const duration = scene.duration * fps;
    currentFrame += duration;
    if (i < config.scenes.length - 1) {
      currentFrame -= overlapFrames;
    }
    // Per-scene layout override, or even/odd alternation
    const layout: LayoutMode = scene.layout ?? (i % 2 === 0 ? "bleed" : "framed");
    return { scene, from, duration, index: i, layout };
  });

  const outroStart = currentFrame;
  const voiceStartFrame = introFrames;
  const totalContentFrames = outroStart - introFrames;

  // Active scene index for BrandBar
  const activeSceneIndex = getActiveSceneIndex(
    frame,
    introFrames,
    sceneEntries,
  );

  /** Voiceover volume — fade out in last 0.5s */
  const voiceVolume = (f: number) => {
    const absFrame = voiceStartFrame + f;
    return interpolate(
      absFrame,
      [durationInFrames - fps * 0.5, durationInFrames],
      [1, 0],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );
  };

  /** BGM volume — peak at intro/outro, ambient under voiceover */
  const bgmVolume = (f: number) => {
    const peak = BGM_VOLUME;
    const ambient = BGM_AMBIENT;

    if (f < introFrames) {
      const fadeIn = interpolate(f, [0, fps], [0, peak], {
        extrapolateRight: "clamp",
      });
      const fadeOut = interpolate(
        f,
        [introFrames - fps, introFrames],
        [peak, ambient],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
      );
      return Math.min(fadeIn, fadeOut);
    }

    if (f < outroStart) return ambient;

    const outroLocal = f - outroStart;
    const fadeIn = interpolate(outroLocal, [0, fps], [ambient, peak], {
      extrapolateRight: "clamp",
    });
    const fadeOut = interpolate(
      outroLocal,
      [outroFrames - fps * 2, outroFrames],
      [peak, 0],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );
    return Math.min(fadeIn, fadeOut);
  };

  return (
    <AbsoluteFill>
      {/* Intro */}
      <Sequence durationInFrames={introFrames}>
        <Intro meta={config.meta} />
      </Sequence>

      {/* Scenes — overlapping for cross-dissolve */}
      {sceneEntries.map(({ scene, from, duration, index, layout }) => (
        <Sequence key={scene.id} from={from} durationInFrames={duration}>
          <SceneSlide
            image={scene.image}
            sceneIndex={index}
            layout={layout}
            panDir={scene.panDir}
            zoomDir={scene.zoomDir}
          />
          {/* Dynamic visual layers — atmospheric depth */}
          <AmbientParticles sceneIndex={index} layout={layout} />
          <WaveformDecor sceneIndex={index} />
          <LightLeak sceneIndex={index} />
          {/* Scene title overlay at chapter boundaries */}
          <SceneTitleOverlay
            label={scene.label || ""}
            isChapterBoundary={isChapterBoundary(index, chapters)}
          />
        </Sequence>
      ))}

      {/* Outro */}
      <Sequence from={outroStart} durationInFrames={outroFrames}>
        <Outro
          ctaText={config.outro.ctaText}
          nextBookTitle={config.outro.nextBookTitle}
        />
      </Sequence>

      {/* Voiceover — starts after intro */}
      <Sequence from={voiceStartFrame}>
        <Audio src={staticFile("audio/voiceover.wav")} volume={voiceVolume} />
      </Sequence>

      {/* BGM */}
      {config.hasBgm && (
        <Audio src={staticFile("bgm/bgm.mp3")} volume={bgmVolume} loop />
      )}

      {/* Vignette — over scenes only */}
      <Sequence from={introFrames} durationInFrames={totalContentFrames}>
        <Vignette />
      </Sequence>

      {/* Corner accents — editorial brackets, above vignette */}
      {sceneEntries.map(({ scene, from, duration, index, layout }) => (
        <Sequence
          key={`corner-${scene.id}`}
          from={from}
          durationInFrames={duration}
        >
          <CornerAccents sceneIndex={index} layout={layout} />
        </Sequence>
      ))}

      {/* Grain overlay — subtle texture */}
      <Sequence from={introFrames} durationInFrames={totalContentFrames}>
        <GrainOverlay />
      </Sequence>

      {/* BrandBar — persistent during content */}
      <Sequence from={introFrames} durationInFrames={totalContentFrames}>
        <BrandBar
          title={config.title}
          chapters={chapters}
          activeSceneIndex={activeSceneIndex}
          totalContentFrames={totalContentFrames}
          contentStartFrame={introFrames}
        />
      </Sequence>

      {/* Subtitle overlay — above BrandBar */}
      <Sequence from={0}>
        <Subtitle
          offsetMs={(introFrames / fps) * 1000}
          adjustMs={config.subtitleAdjustMs ?? 0}
        />
      </Sequence>
    </AbsoluteFill>
  );
};
