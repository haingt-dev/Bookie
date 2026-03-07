import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";

/**
 * CSS-based film grain overlay to unify AI-generated images.
 * Uses a pseudo-random offset per frame for subtle noise effect.
 */
export const GrainOverlay: React.FC = () => {
  const frame = useCurrentFrame();

  // Shift the SVG noise pattern slightly each frame for animation
  const offsetX = (frame * 7) % 200;
  const offsetY = (frame * 13) % 200;

  return (
    <AbsoluteFill
      style={{
        opacity: 0.03,
        pointerEvents: "none",
        mixBlendMode: "overlay",
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        backgroundPosition: `${offsetX}px ${offsetY}px`,
      }}
    />
  );
};
