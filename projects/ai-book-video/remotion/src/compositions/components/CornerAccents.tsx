import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, COLORS, CORNER, FRAME, VIDEO } from "../../constants";
import type { LayoutMode } from "../../types";
import { SPRINGS } from "../../utils/springs";

interface CornerAccentsProps {
  sceneIndex: number;
  layout: LayoutMode;
}

// 4 corner configurations cycling per scene
const CONFIGS: Array<[string, string]> = [
  ["top-left", "bottom-right"],
  ["top-right", "bottom-left"],
  ["top-left", "top-right"],
  ["bottom-left", "bottom-right"],
];

function getCornerPosition(
  corner: string,
  inset: number,
): { cx: number; cy: number; hDir: number; vDir: number } {
  const isTop = corner.includes("top");
  const isLeft = corner.includes("left");
  return {
    cx: isLeft ? inset : VIDEO.width - inset,
    cy: isTop ? inset : VIDEO.height - inset,
    hDir: isLeft ? 1 : -1,
    vDir: isTop ? 1 : -1,
  };
}

export const CornerAccents: React.FC<CornerAccentsProps> = ({
  sceneIndex,
  layout,
}) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const corners = CONFIGS[sceneIndex % CONFIGS.length];
  const inset =
    layout === "framed"
      ? FRAME.padding + CORNER.insetFramed
      : CORNER.insetBleed;

  // Spring entry — lines grow from corner point
  const lineProgress = spring({
    frame: Math.max(0, frame - ANIM.fadeFrames),
    fps,
    config: SPRINGS.cornerAccent,
  });

  // Breathing opacity — keeps brackets alive after spring settles
  const breathe =
    CORNER.breatheBase + Math.sin(frame * CORNER.breatheFreq) * CORNER.breatheAmp;

  // Fade out before scene exit
  const fadeOut = interpolate(
    frame,
    [durationInFrames - ANIM.fadeFrames * 2, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  const opacity = breathe * fadeOut;
  const armLength = CORNER.lineLength * lineProgress;

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <svg
        width={VIDEO.width}
        height={VIDEO.height}
        viewBox={`0 0 ${VIDEO.width} ${VIDEO.height}`}
        style={{ position: "absolute", top: 0, left: 0 }}
      >
        {corners.map((corner) => {
          const { cx, cy, hDir, vDir } = getCornerPosition(corner, inset);
          return (
            <g key={corner} opacity={opacity}>
              {/* Horizontal arm */}
              <line
                x1={cx}
                y1={cy}
                x2={cx + armLength * hDir}
                y2={cy}
                stroke={COLORS.gold}
                strokeWidth={CORNER.lineWidth}
              />
              {/* Vertical arm */}
              <line
                x1={cx}
                y1={cy}
                x2={cx}
                y2={cy + armLength * vDir}
                stroke={COLORS.gold}
                strokeWidth={CORNER.lineWidth}
              />
              {/* Corner dot */}
              <circle
                cx={cx}
                cy={cy}
                r={CORNER.dotRadius}
                fill={COLORS.gold}
              />
            </g>
          );
        })}
      </svg>
    </AbsoluteFill>
  );
};
