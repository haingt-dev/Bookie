import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, COLORS } from "../../constants";

interface SceneSlideProps {
  image: string;
}

export const SceneSlide: React.FC<SceneSlideProps> = ({ image }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  // Fade in/out
  const opacity = interpolate(
    frame,
    [0, ANIM.fadeFrames, durationInFrames - ANIM.fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Ken Burns: slow zoom 1.0 → 1.05
  const scale = interpolate(
    frame,
    [0, durationInFrames],
    [1, ANIM.kenBurnsScale],
    { extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
      <AbsoluteFill style={{ opacity }}>
        <Img
          src={staticFile(`scenes/${image}`)}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            transform: `scale(${scale})`,
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
