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
import { ANIM, COLORS, FRAME } from "../../constants";
import type { LayoutMode, PanDirection, ZoomDirection } from "../../types";
import { SPRINGS } from "../../utils/springs";

interface SceneSlideProps {
  image: string;
  sceneIndex: number;
  layout: LayoutMode;
  panDir?: PanDirection;
  zoomDir?: ZoomDirection;
}

// 4 spring Ken Burns presets — cycled per scene when no explicit direction
const KB_PRESETS = [
  { scaleFrom: 1, scaleTo: ANIM.kenBurnsScale, xFrom: 0, xTo: 0, yFrom: 0, yTo: 0 }, // zoom-in
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: -ANIM.kenBurnsPanPx, yFrom: 0, yTo: 0 }, // pan-right
  { scaleFrom: ANIM.kenBurnsScale, scaleTo: 1, xFrom: 0, xTo: 0, yFrom: 0, yTo: 0 }, // zoom-out
  { scaleFrom: 1.05, scaleTo: 1.05, xFrom: 0, xTo: ANIM.kenBurnsPanPx, yFrom: 0, yTo: 0 }, // pan-left
] as const;

type KBPreset = { scaleFrom: number; scaleTo: number; xFrom: number; xTo: number; yFrom: number; yTo: number };

function resolveKenBurns(
  sceneIndex: number,
  panDir?: PanDirection,
  zoomDir?: ZoomDirection,
): KBPreset {
  if (!panDir && !zoomDir) {
    return KB_PRESETS[sceneIndex % KB_PRESETS.length];
  }

  const pan = ANIM.kenBurnsPanPx;
  const scale = ANIM.kenBurnsScale;

  let scaleFrom = 1, scaleTo = 1;
  let xFrom = 0, xTo = 0, yFrom = 0, yTo = 0;

  const zoom = zoomDir ?? "none";
  if (zoom === "in") { scaleFrom = 1; scaleTo = scale; }
  else if (zoom === "out") { scaleFrom = scale; scaleTo = 1; }

  const p = panDir ?? "none";
  if (p === "left") { xTo = pan; }
  if (p === "right") { xTo = -pan; }
  if (p === "up") { yTo = pan; }
  if (p === "down") { yTo = -pan; }

  // Pan-only: apply constant slight scale for motion feel
  if (zoom === "none" && p !== "none") {
    scaleFrom = 1.05; scaleTo = 1.05;
  }

  return { scaleFrom, scaleTo, xFrom, xTo, yFrom, yTo };
}

export const SceneSlide: React.FC<SceneSlideProps> = ({
  image,
  sceneIndex,
  layout,
  panDir,
  zoomDir,
}) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Cross-dissolve opacity
  const opacity = interpolate(
    frame,
    [0, ANIM.fadeFrames, durationInFrames - ANIM.fadeFrames, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Cross-dissolve blur — cinematic sharpening on entry
  const dissolveBlur = interpolate(
    frame,
    [0, ANIM.fadeFrames],
    [2, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Spring-based Ken Burns progress
  const preset = resolveKenBurns(sceneIndex, panDir, zoomDir);
  const progress = spring({
    frame,
    fps,
    config: SPRINGS.kenBurns,
    durationInFrames,
  });

  const scale = preset.scaleFrom + (preset.scaleTo - preset.scaleFrom) * progress;
  const tx = preset.xFrom + (preset.xTo - preset.xFrom) * progress;
  const ty = preset.yFrom + (preset.yTo - preset.yFrom) * progress;

  const imgElement = (
    <Img
      src={staticFile(`scenes/${image}`)}
      style={{
        width: "100%",
        height: "100%",
        objectFit: "cover",
        transform: `scale(${scale}) translate(${tx}px, ${ty}px)`,
        filter: dissolveBlur > 0.01 ? `blur(${dissolveBlur}px)` : undefined,
      }}
    />
  );

  if (layout === "framed") {
    return (
      <AbsoluteFill style={{ backgroundColor: COLORS.sage }}>
        <AbsoluteFill style={{ opacity }}>
          <div
            style={{
              position: "absolute",
              top: FRAME.padding,
              left: FRAME.padding,
              right: FRAME.padding,
              bottom: FRAME.padding,
              borderRadius: FRAME.borderRadius,
              overflow: "hidden",
              boxShadow: FRAME.shadow,
            }}
          >
            {imgElement}
          </div>
        </AbsoluteFill>
      </AbsoluteFill>
    );
  }

  // Default: bleed (full frame)
  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.background }}>
      <AbsoluteFill style={{ opacity }}>{imgElement}</AbsoluteFill>
    </AbsoluteFill>
  );
};
