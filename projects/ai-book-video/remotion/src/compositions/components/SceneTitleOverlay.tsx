import React from "react";
import {
  AbsoluteFill,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, BRAND_BAR, COLORS } from "../../constants";
import { SPRINGS } from "../../utils/springs";

interface SceneTitleOverlayProps {
  label: string;
  isChapterBoundary: boolean;
}

export const SceneTitleOverlay: React.FC<SceneTitleOverlayProps> = ({
  label,
  isChapterBoundary,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  if (!isChapterBoundary || !label) return null;

  const titleDurationFrames = ANIM.sceneTitleDurationS * fps;

  // Spring reveal — slide from left
  const revealProgress = spring({
    frame,
    fps,
    config: SPRINGS.chapterReveal,
  });

  const fadeOut =
    frame > titleDurationFrames - fps * 0.5
      ? Math.max(
          0,
          1 - (frame - (titleDurationFrames - fps * 0.5)) / (fps * 0.5),
        )
      : 1;

  const opacity = revealProgress * fadeOut;
  const translateX = (1 - revealProgress) * -30;

  // Position above BrandBar
  const bottomPx = BRAND_BAR.height + BRAND_BAR.progressHeight + 24;

  return (
    <AbsoluteFill
      style={{
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          position: "absolute",
          bottom: bottomPx,
          left: 48,
          display: "inline-flex",
          alignItems: "stretch",
          opacity,
          transform: `translateX(${translateX}px)`,
          backdropFilter: "blur(16px)",
          borderRadius: 6,
          boxShadow: "0 4px 20px rgba(0, 0, 0, 0.2)",
        }}
      >
        {/* Gold accent bar */}
        <div
          style={{
            width: 3,
            backgroundColor: COLORS.gold,
            borderRadius: "6px 0 0 6px",
            flexShrink: 0,
          }}
        />
        {/* Label */}
        <div
          style={{
            backgroundColor: "rgba(10, 15, 10, 0.65)",
            paddingLeft: 20,
            paddingRight: 28,
            paddingTop: 14,
            paddingBottom: 14,
            borderRadius: "0 6px 6px 0",
          }}
        >
          <span
            style={{
              fontFamily: "Inter",
              fontWeight: 500,
              fontSize: 22,
              color: COLORS.white,
              letterSpacing: 2,
              textTransform: "uppercase",
              opacity: 0.95,
            }}
          >
            {label}
          </span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
