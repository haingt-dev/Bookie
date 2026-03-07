import React, { useMemo } from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { AMBIENT, ANIM, COLORS, FRAME, VIDEO } from "../../constants";
import type { LayoutMode } from "../../types";
import { seededRandom } from "../../utils/seededRandom";

interface AmbientParticlesProps {
  sceneIndex: number;
  layout: LayoutMode;
}

interface Particle {
  x0: number;
  y0: number;
  size: number;
  baseOpacity: number;
  blur: number;
  color: string;
  freqX: number;
  freqY: number;
  phaseX: number;
  phaseY: number;
  amplitudeX: number;
  amplitudeY: number;
}

const PARTICLE_COLORS = [
  COLORS.gold,
  COLORS.gold,
  COLORS.primary,
  COLORS.white,
  COLORS.white,
]; // 40% gold, 20% green, 40% white

function lerp(min: number, max: number, t: number): number {
  return min + (max - min) * t;
}

function generateParticles(
  sceneIndex: number,
  layout: LayoutMode,
): Particle[] {
  const rand = seededRandom(sceneIndex * 7919);
  const minX = layout === "framed" ? FRAME.padding : 0;
  const maxX = layout === "framed" ? VIDEO.width - FRAME.padding : VIDEO.width;
  const minY = layout === "framed" ? FRAME.padding : 0;
  const maxY =
    layout === "framed" ? VIDEO.height - FRAME.padding : VIDEO.height;

  return Array.from({ length: AMBIENT.count }, () => ({
    x0: lerp(minX, maxX, rand()),
    y0: lerp(minY, maxY, rand()),
    size: lerp(AMBIENT.sizeMin, AMBIENT.sizeMax, rand()),
    baseOpacity: lerp(AMBIENT.opacityMin, AMBIENT.opacityMax, rand()),
    blur: lerp(AMBIENT.blurMin, AMBIENT.blurMax, rand()),
    color: PARTICLE_COLORS[Math.floor(rand() * PARTICLE_COLORS.length)],
    freqX: lerp(AMBIENT.freqX[0], AMBIENT.freqX[1], rand()),
    freqY: lerp(AMBIENT.freqY[0], AMBIENT.freqY[1], rand()),
    phaseX: rand() * Math.PI * 2,
    phaseY: rand() * Math.PI * 2,
    amplitudeX: lerp(AMBIENT.amplitudeX[0], AMBIENT.amplitudeX[1], rand()),
    amplitudeY: lerp(AMBIENT.amplitudeY[0], AMBIENT.amplitudeY[1], rand()),
  }));
}

export const AmbientParticles: React.FC<AmbientParticlesProps> = ({
  sceneIndex,
  layout,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const particles = useMemo(
    () => generateParticles(sceneIndex, layout),
    [sceneIndex, layout],
  );

  // Fade envelope — syncs with scene cross-dissolve
  const fadeEnvelope = interpolate(
    frame,
    [
      0,
      ANIM.fadeFrames * 2,
      durationInFrames - ANIM.fadeFrames * 2,
      durationInFrames,
    ],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Larger particles drift slower (visual weight)
  const sizeRange = AMBIENT.sizeMax - AMBIENT.sizeMin;

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {particles.map((p, i) => {
        const speedMul = 1 - (p.size - AMBIENT.sizeMin) / sizeRange * 0.5;
        const x =
          p.x0 +
          Math.sin(frame * p.freqX * speedMul + p.phaseX) * p.amplitudeX;
        const y =
          p.y0 +
          Math.sin(frame * p.freqY * speedMul + p.phaseY) * p.amplitudeY;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              backgroundColor: p.color,
              opacity: p.baseOpacity * fadeEnvelope,
              filter: `blur(${p.blur}px)`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};
