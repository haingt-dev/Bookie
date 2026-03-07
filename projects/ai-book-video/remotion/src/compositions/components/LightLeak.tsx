import React from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, LIGHT_LEAK } from "../../constants";

interface LightLeakProps {
  sceneIndex: number;
}

export const LightLeak: React.FC<LightLeakProps> = ({ sceneIndex }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const preset = LIGHT_LEAK.presets[sceneIndex % LIGHT_LEAK.presets.length];

  // Sweep progress — full scene duration
  const progress = interpolate(frame, [0, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const cx = preset.startX + (preset.endX - preset.startX) * progress;
  const cy = preset.startY + (preset.endY - preset.startY) * progress;

  // Fade envelope — syncs with scene cross-dissolve
  const fadeEnvelope = interpolate(
    frame,
    [0, ANIM.fadeFrames, durationInFrames - ANIM.fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: `radial-gradient(ellipse 600px 400px at ${cx}% ${cy}%, ${preset.color}, transparent)`,
          transform: `rotate(${preset.angle}deg)`,
          filter: `blur(${LIGHT_LEAK.blurPx}px)`,
          opacity: fadeEnvelope,
          mixBlendMode: "screen",
        }}
      />
    </AbsoluteFill>
  );
};
