import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { BRAND_BAR, COLORS } from "../../constants";
import type { ChapterInfo } from "../../types";

interface BrandBarProps {
  title: string;
  chapters: ChapterInfo[];
  activeSceneIndex: number;
  totalContentFrames: number;
  contentStartFrame: number;
}

export const BrandBar: React.FC<BrandBarProps> = ({
  title,
  chapters,
  activeSceneIndex,
  totalContentFrames,
  contentStartFrame,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const contentFrame = frame - contentStartFrame;
  const progress = Math.max(
    0,
    Math.min(contentFrame / totalContentFrames, 1),
  );

  // Fade in/out
  const opacity = interpolate(
    contentFrame,
    [0, fps * 0.5, totalContentFrames - fps, totalContentFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Find which chapter is active
  const activeChapter = chapters.findIndex(
    (ch) =>
      activeSceneIndex >= ch.startIndex && activeSceneIndex <= ch.endIndex,
  );

  return (
    <AbsoluteFill style={{ opacity }}>
      {/* Progress bar — full width at very bottom */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: BRAND_BAR.progressHeight,
          backgroundColor: "rgba(255, 255, 255, 0.1)",
        }}
      >
        <div
          style={{
            width: `${progress * 100}%`,
            height: "100%",
            backgroundColor: COLORS.primary,
            boxShadow: `0 0 8px ${BRAND_BAR.glowColor}`,
          }}
        />
      </div>

      {/* Bar content — gradient background */}
      <div
        style={{
          position: "absolute",
          bottom: BRAND_BAR.progressHeight,
          left: 0,
          right: 0,
          height: BRAND_BAR.height,
          background:
            "linear-gradient(to top, rgba(10, 15, 10, 0.75), rgba(10, 15, 10, 0.55))",
          backdropFilter: "blur(16px)",
          borderTop: "1px solid rgba(255, 255, 255, 0.08)",
          display: "flex",
          alignItems: "center",
          paddingLeft: BRAND_BAR.paddingX,
          paddingRight: BRAND_BAR.paddingX,
        }}
      >
        {/* Logo */}
        <Img
          src={staticFile("logomark.png")}
          style={{
            height: BRAND_BAR.logoHeight,
            marginRight: 16,
            opacity: 0.9,
            filter: "brightness(10)",
          }}
        />

        {/* Title */}
        <span
          style={{
            fontFamily: "Inter",
            fontSize: BRAND_BAR.fontSize,
            color: COLORS.white,
            fontWeight: 300,
            letterSpacing: 1,
            opacity: 0.7,
            marginRight: "auto",
          }}
        >
          {title}
        </span>

        {/* Chapter dots */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: BRAND_BAR.dotGap,
          }}
        >
          {chapters.map((_, i) => {
            const isActive = i === activeChapter;
            const isPast = i < activeChapter;
            return (
              <div
                key={i}
                style={{
                  width: BRAND_BAR.dotSize,
                  height: BRAND_BAR.dotSize,
                  borderRadius: "50%",
                  backgroundColor: isActive
                    ? COLORS.primary
                    : isPast
                      ? "rgba(255, 255, 255, 0.7)"
                      : "rgba(255, 255, 255, 0.2)",
                  boxShadow: isActive
                    ? `0 0 0 3px rgba(27, 107, 42, 0.3)`
                    : "none",
                  transition: "background-color 0.3s, box-shadow 0.3s",
                }}
              />
            );
          })}
        </div>
      </div>
    </AbsoluteFill>
  );
};
