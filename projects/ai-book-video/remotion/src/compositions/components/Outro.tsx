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

interface OutroProps {
  ctaText: string;
  nextBookTitle: string;
}

export const Outro: React.FC<OutroProps> = ({ ctaText, nextBookTitle }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, fps * 0.5], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(
    frame,
    [durationInFrames - fps * 1.5, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const opacity = Math.min(fadeIn, fadeOut);

  // Logo spring
  const logoScale = spring({
    frame,
    fps,
    config: { damping: 15, mass: 0.5 },
  });

  // CTA stagger
  const ctaOpacity = interpolate(
    frame,
    [fps * 0.5, fps * 1.2],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const ctaY = interpolate(
    frame,
    [fps * 0.5, fps * 1.2],
    [15, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Divider draw-in
  const dividerProgress = spring({
    frame: Math.max(0, frame - fps * 1.0),
    fps,
    config: { damping: 30, stiffness: 100, mass: 0.6 },
  });

  // URL stagger
  const urlOpacity = interpolate(
    frame,
    [fps * 1.5, fps * 2.2],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Next book stagger
  const nextBookOpacity = interpolate(
    frame,
    [fps * 2.5, fps * 3.5],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const nextBookY = interpolate(
    frame,
    [fps * 2.5, fps * 3.5],
    [10, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
      {/* Warm glow — matching Intro */}
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
          opacity,
        }}
      >
        <div style={{ textAlign: "center", maxWidth: 900 }}>
          {/* Logo with spring */}
          <Img
            src={staticFile("logomark.png")}
            style={{
              height: 60,
              marginBottom: 28,
              transform: `scale(${logoScale})`,
            }}
          />

          {/* CTA */}
          <div
            style={{
              opacity: ctaOpacity,
              transform: `translateY(${ctaY}px)`,
              fontSize: 52,
              fontWeight: 700,
              color: COLORS.ink,
              fontFamily: "Lora",
              marginBottom: 28,
              lineHeight: 1.2,
            }}
          >
            {ctaText}
          </div>

          {/* Gold divider */}
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              marginBottom: 28,
              opacity: dividerProgress,
            }}
          >
            <div
              style={{
                width: INTRO.dividerWidth * dividerProgress,
                height: INTRO.dividerHeight,
                backgroundColor: COLORS.gold,
                borderRadius: 1,
              }}
            />
          </div>

          {/* URL as subtle pill */}
          <div
            style={{
              opacity: urlOpacity,
              display: "inline-flex",
              alignItems: "center",
              backgroundColor: "rgba(27, 107, 42, 0.1)",
              paddingLeft: 24,
              paddingRight: 24,
              paddingTop: 10,
              paddingBottom: 10,
              borderRadius: 24,
              marginBottom: 48,
            }}
          >
            <span
              style={{
                fontSize: 20,
                color: COLORS.primary,
                fontFamily: "Inter",
                fontWeight: 500,
                letterSpacing: 0.5,
              }}
            >
              bookiecommunity.com
            </span>
          </div>

          {/* Next book */}
          {nextBookTitle && (
            <div
              style={{
                opacity: nextBookOpacity,
                transform: `translateY(${nextBookY}px)`,
                fontSize: 24,
                color: COLORS.textDark,
                fontFamily: "Inter",
                fontWeight: 300,
              }}
            >
              <span style={{ color: COLORS.gold, marginRight: 8 }}>
                &#9656;
              </span>
              <span style={{ color: COLORS.textLight }}>
                {"Cu\u1ED1n ti\u1EBFp theo: "}
              </span>
              {nextBookTitle}
            </div>
          )}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
