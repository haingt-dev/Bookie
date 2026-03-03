import React from "react";
import {
  AbsoluteFill,
  Audio,
  interpolate,
  Sequence,
  staticFile,
  useVideoConfig,
} from "remotion";
import { BGM_AMBIENT, BGM_VOLUME } from "../constants";
import type { VideoConfig } from "../types";
import { Intro } from "./components/Intro";
import { Outro } from "./components/Outro";
import { SceneSlide } from "./components/SceneSlide";
import { Subtitle } from "./components/Subtitle";

export const BookVideo: React.FC<{ config: VideoConfig }> = ({ config }) => {
  const { fps, durationInFrames } = useVideoConfig();
  const introFrames = config.intro.duration * fps;
  const outroFrames = config.outro.duration * fps;

  // Calculate scene start frames
  let currentFrame = introFrames;
  const sceneEntries = config.scenes.map((scene) => {
    const from = currentFrame;
    const duration = scene.duration * fps;
    currentFrame += duration;
    return { scene, from, duration };
  });

  const outroStart = currentFrame;
  const voiceStartFrame = introFrames;

  /** Voiceover volume — fade out in last 0.5s as safety net */
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

    // Intro section: fade in → peak → fade down to ambient
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

    // Scenes section — ambient under voiceover
    if (f < outroStart) return ambient;

    // Outro section: fade up to peak → fade out to 0
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
        <Intro />
      </Sequence>

      {/* Scenes */}
      {sceneEntries.map(({ scene, from, duration }) => (
        <Sequence key={scene.id} from={from} durationInFrames={duration}>
          <SceneSlide image={scene.image} />
        </Sequence>
      ))}

      {/* Outro */}
      <Sequence from={outroStart} durationInFrames={outroFrames}>
        <Outro
          ctaText={config.outro.ctaText}
          nextBookTitle={config.outro.nextBookTitle}
        />
      </Sequence>

      {/* Voiceover — starts after intro, fades out near end */}
      <Sequence from={voiceStartFrame}>
        <Audio src={staticFile("audio/voiceover.wav")} volume={voiceVolume} />
      </Sequence>

      {/* BGM — ambient throughout, peak at intro/outro */}
      {config.hasBgm && (
        <Audio src={staticFile("bgm/bgm.mp3")} volume={bgmVolume} loop />
      )}

      {/* Subtitle overlay — offset by intro duration + fine-tune adjust */}
      <Sequence from={0}>
        <Subtitle
          offsetMs={(introFrames / fps) * 1000}
          adjustMs={config.subtitleAdjustMs ?? 0}
        />
      </Sequence>
    </AbsoluteFill>
  );
};
