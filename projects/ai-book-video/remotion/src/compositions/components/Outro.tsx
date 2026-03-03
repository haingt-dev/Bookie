import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { COLORS } from "../../constants";

interface OutroProps {
  ctaText: string;
  nextBookTitle: string;
}

export const Outro: React.FC<OutroProps> = ({ ctaText, nextBookTitle }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const { durationInFrames } = useVideoConfig();
  const outroFrames = durationInFrames; // local frame count within this Sequence

  const fadeIn = interpolate(frame, [0, fps * 0.5], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(
    frame,
    [outroFrames - fps * 1.5, outroFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const opacity = Math.min(fadeIn, fadeOut);

  const nextBookOpacity = interpolate(
    frame,
    [fps * 2, fps * 3],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill
      style={{
        backgroundColor: COLORS.background,
        justifyContent: "center",
        alignItems: "center",
        opacity,
      }}
    >
      <div style={{ textAlign: "center", maxWidth: 900 }}>
        <Img
          src={staticFile("logomark.png")}
          style={{ height: 60, marginBottom: 24 }}
        />

        <div
          style={{
            fontSize: 56,
            fontWeight: 700,
            color: COLORS.accent,
            fontFamily: "Montserrat",
            marginBottom: 24,
          }}
        >
          {ctaText}
        </div>

        <div
          style={{
            fontSize: 20,
            color: COLORS.textLight,
            fontFamily: "Inter",
            marginBottom: 60,
          }}
        >
          bookiecommunity.com
        </div>

        {nextBookTitle && (
          <div
            style={{
              opacity: nextBookOpacity,
              fontSize: 24,
              color: COLORS.textDark,
              fontFamily: "Inter",
            }}
          >
            <span style={{ color: COLORS.secondary }}>Cuốn tiếp theo: </span>
            {nextBookTitle}
          </div>
        )}
      </div>
    </AbsoluteFill>
  );
};
