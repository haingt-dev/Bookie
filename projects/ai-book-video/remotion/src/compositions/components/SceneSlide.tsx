import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, COLORS } from "../../constants";

interface SceneSlideProps {
  image: string;
  sceneIndex: number;
}

// Ken Burns motion presets — auto-cycled per scene for variety
const KB_PRESETS = [
  // zoom-in
  { scaleFrom: 1, scaleTo: ANIM.kenBurnsScale, xFrom: 0, xTo: 0, yFrom: 0, yTo: 0 },
  // pan-right
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: -ANIM.kenBurnsPanPx, yFrom: 0, yTo: 0 },
  // zoom-out
  { scaleFrom: ANIM.kenBurnsScale, scaleTo: 1, xFrom: 0, xTo: 0, yFrom: 0, yTo: 0 },
  // pan-left
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: ANIM.kenBurnsPanPx, yFrom: 0, yTo: 0 },
  // pan-up
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: 0, yFrom: 0, yTo: 20 },
  // pan-down
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: 0, yFrom: 0, yTo: -20 },
] as const;

const coverStyle: React.CSSProperties = {
  width: "100%",
  height: "100%",
  objectFit: "cover",
};

export const SceneSlide: React.FC<SceneSlideProps> = ({ image, sceneIndex }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  // Fade in/out for cross-dissolve
  const opacity = interpolate(
    frame,
    [0, ANIM.fadeFrames, durationInFrames - ANIM.fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Pick Ken Burns preset based on scene index
  const preset = KB_PRESETS[sceneIndex % KB_PRESETS.length];

  // Eased progress 0→1 over the scene duration
  const progress = interpolate(frame, [0, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.ease),
  });

  const scale = preset.scaleFrom + (preset.scaleTo - preset.scaleFrom) * progress;
  const tx = preset.xFrom + (preset.xTo - preset.xFrom) * progress;
  const ty = preset.yFrom + (preset.yTo - preset.yFrom) * progress;

  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
      <AbsoluteFill style={{ opacity }}>
        <Img
          src={staticFile(`scenes/${image}`)}
          style={{
            ...coverStyle,
            transform: `scale(${scale}) translate(${tx}px, ${ty}px)`,
          }}
        />
      </AbsoluteFill>

      {/* Logo watermark */}
      <Img
        src={staticFile("logomark.png")}
        style={{
          position: "absolute",
          bottom: 30,
          right: 30,
          height: 40,
          opacity: ANIM.logoOpacity,
          filter: "drop-shadow(0 1px 4px rgba(0,0,0,0.5))",
        }}
      />
    </AbsoluteFill>
  );
};
