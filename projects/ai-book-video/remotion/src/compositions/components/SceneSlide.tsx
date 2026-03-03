import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, COLORS } from "../../constants";

interface SceneSlideProps {
  image: string;
  layers?: {
    fg: string;
    bg?: string;
  };
}

const coverStyle: React.CSSProperties = {
  width: "100%",
  height: "100%",
  objectFit: "cover",
};

export const SceneSlide: React.FC<SceneSlideProps> = ({ image, layers }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Fade in/out — shared by both modes
  const opacity = interpolate(
    frame,
    [0, ANIM.fadeFrames, durationInFrames - ANIM.fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // === PARALLAX MODE ===
  if (layers) {
    const bgImage = layers.bg ?? image;
    const fgImage = layers.fg;

    // Background: slow horizontal drift + overscan scale
    const bgX = interpolate(
      frame,
      [0, durationInFrames],
      [0, -ANIM.parallaxBgTravel],
      { extrapolateRight: "clamp" }
    );

    // Foreground: faster drift (creates depth relative to background)
    const fgDriftX = interpolate(
      frame,
      [0, durationInFrames],
      [10, -ANIM.parallaxFgTravel],
      { extrapolateRight: "clamp" }
    );

    // Foreground spring entry — arrives from below
    const fgEntry = spring({
      frame,
      fps,
      durationInFrames: ANIM.parallaxEntryFrames,
      config: { damping: 14, stiffness: 100 },
    });
    const fgY = interpolate(fgEntry, [0, 1], [ANIM.parallaxEntryOffset, 0]);
    const fgScale = interpolate(fgEntry, [0, 1], [0.95, 1]);

    return (
      <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
        {/* Background — inpainted, slow drift */}
        <AbsoluteFill style={{ opacity }}>
          <Img
            src={staticFile(`scenes/${bgImage}`)}
            style={{
              ...coverStyle,
              transform: `scale(${ANIM.parallaxBgScale}) translateX(${bgX}px)`,
            }}
          />
        </AbsoluteFill>

        {/* Foreground — alpha PNG, faster drift + spring entry */}
        <AbsoluteFill
          style={{
            opacity,
            transform: `translateX(${fgDriftX}px) translateY(${fgY}px) scale(${fgScale})`,
          }}
        >
          <Img src={staticFile(`scenes/${fgImage}`)} style={coverStyle} />
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
  }

  // === KEN BURNS MODE (default) ===
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
            ...coverStyle,
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
