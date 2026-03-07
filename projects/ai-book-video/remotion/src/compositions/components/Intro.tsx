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
import { COLORS, INTRO } from "../../constants";
import type { VideoMeta } from "../../types";
import { SPRINGS } from "../../utils/springs";

interface IntroProps {
  meta?: VideoMeta;
}

export const Intro: React.FC<IntroProps> = ({ meta }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const fadeOut = interpolate(
    frame,
    [durationInFrames - fps * 0.5, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  if (meta) {
    // Logo — subtle breathing pulse
    const logoScale = spring({
      frame,
      fps,
      config: { damping: 15, mass: 0.4 },
    });
    const logoPulse =
      1 + Math.sin((frame / fps) * 1.5) * 0.015; // subtle 0.015 amplitude

    // Book title — dramatic spring reveal
    const titleProgress = spring({
      frame: Math.max(0, frame - fps * 0.5),
      fps,
      config: SPRINGS.introTitle,
    });
    const titleOpacity = interpolate(
      frame,
      [fps * 0.5, fps * 1.2],
      [0, 1],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );

    // Gold divider — draws in from center
    const dividerProgress = spring({
      frame: Math.max(0, frame - fps * 1.2),
      fps,
      config: SPRINGS.introDivider,
    });

    // Author — elegant fade up
    const authorOpacity = interpolate(
      frame,
      [fps * 1.6, fps * 2.2],
      [0, 1],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );
    const authorY = interpolate(
      frame,
      [fps * 1.6, fps * 2.2],
      [12, 0],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );

    // Angle / thesis — last to appear
    const angleOpacity = interpolate(
      frame,
      [fps * 2.2, fps * 3.0],
      [0, 1],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );
    const angleY = interpolate(
      frame,
      [fps * 2.2, fps * 3.0],
      [10, 0],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    );

    return (
      <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
        {/* Warm glow overlay */}
        <AbsoluteFill
          style={{
            background: INTRO.warmGlow,
            pointerEvents: "none",
          }}
        />

        <AbsoluteFill style={{ opacity: fadeOut }}>
          {/* Logo — small, top-left with breathing */}
          <div
            style={{
              position: "absolute",
              top: 44,
              left: 44,
              transform: `scale(${logoScale * logoPulse})`,
              transformOrigin: "top left",
            }}
          >
            <Img src={staticFile("logomark.png")} style={{ height: 32 }} />
          </div>

          {/* Book info — centered */}
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              height: "100%",
              paddingLeft: 140,
              paddingRight: 140,
            }}
          >
            {/* Book title */}
            <div
              style={{
                opacity: titleOpacity,
                transform: `translateY(${(1 - titleProgress) * 40}px)`,
                fontSize: 72,
                fontWeight: 700,
                color: COLORS.ink,
                fontFamily: "Lora",
                textAlign: "center",
                lineHeight: 1.15,
                letterSpacing: -1,
              }}
            >
              {meta.bookTitle}
            </div>

            {/* Gold divider — animated draw-in */}
            <div
              style={{
                width: INTRO.dividerWidth * dividerProgress,
                height: INTRO.dividerHeight,
                backgroundColor: COLORS.gold,
                marginTop: 28,
                marginBottom: 28,
                borderRadius: 1,
                opacity: dividerProgress,
              }}
            />

            {/* Author */}
            <div
              style={{
                opacity: authorOpacity,
                transform: `translateY(${authorY}px)`,
                fontSize: 26,
                color: COLORS.textLight,
                fontFamily: "Inter",
                fontWeight: 300,
                textAlign: "center",
                letterSpacing: 0.5,
              }}
            >
              {meta.author}
            </div>

            {/* Angle / thesis */}
            <div
              style={{
                opacity: angleOpacity,
                transform: `translateY(${angleY}px)`,
                fontSize: 30,
                color: COLORS.accent,
                fontFamily: "Be Vietnam Pro",
                fontWeight: 400,
                fontStyle: "italic",
                marginTop: 36,
                textAlign: "center",
                maxWidth: 920,
                lineHeight: 1.45,
              }}
            >
              {meta.angle}
            </div>
          </div>
        </AbsoluteFill>
      </AbsoluteFill>
    );
  }

  // Fallback: generic logo + tagline
  const logoScale = spring({ frame, fps, config: { damping: 12, mass: 0.5 } });

  const taglineOpacity = interpolate(
    frame,
    [fps * 1.5, fps * 2.5],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const taglineY = interpolate(
    frame,
    [fps * 1.5, fps * 2.5],
    [20, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
      {/* Warm glow overlay */}
      <AbsoluteFill
        style={{
          background: INTRO.warmGlow,
          pointerEvents: "none",
        }}
      />

      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
          opacity: fadeOut,
        }}
      >
        <div
          style={{
            transform: `scale(${logoScale})`,
            textAlign: "center",
          }}
        >
          <Img src={staticFile("logo.png")} style={{ height: 120 }} />
        </div>
        <div
          style={{
            opacity: taglineOpacity,
            transform: `translateY(${taglineY}px)`,
            fontSize: 28,
            color: COLORS.textLight,
            fontFamily: "Lora",
            fontWeight: 300,
            marginTop: 16,
            letterSpacing: 4,
            textTransform: "uppercase",
          }}
        >
          Inspires Everyone
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
