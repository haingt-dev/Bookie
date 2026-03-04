import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  staticFile,
  useVideoConfig,
} from "remotion";
import type { VideoConfig } from "../types";
import { SceneSlide } from "./components/SceneSlide";
import { Subtitle } from "./components/Subtitle";

interface BookShortProps {
  config: VideoConfig;
  startScene: number;
  endScene: number;
  voiceStartMs: number;
}

export const BookShort: React.FC<BookShortProps> = ({
  config,
  startScene,
  endScene,
  voiceStartMs,
}) => {
  const { fps } = useVideoConfig();

  const scenes = config.scenes.slice(startScene, endScene + 1);

  let currentFrame = 0;
  const sceneEntries = scenes.map((scene, i) => {
    const from = currentFrame;
    const duration = scene.duration * fps;
    currentFrame += duration;
    return { scene, from, duration, index: startScene + i };
  });

  return (
    <AbsoluteFill>
      {/* Scenes — center-cropped for 9:16 */}
      {sceneEntries.map(({ scene, from, duration, index }) => (
        <Sequence key={scene.id} from={from} durationInFrames={duration}>
          <SceneSlide image={scene.image} sceneIndex={index} />
        </Sequence>
      ))}

      {/* Voiceover — trimmed from voiceStartMs */}
      <Sequence from={0}>
        <Audio
          src={staticFile("audio/voiceover.wav")}
          startFrom={Math.round((voiceStartMs / 1000) * fps)}
        />
      </Sequence>

      {/* Subtitles */}
      <Sequence from={0}>
        <Subtitle offsetMs={-voiceStartMs} />
      </Sequence>
    </AbsoluteFill>
  );
};
