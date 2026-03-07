import React from "react";
import { AbsoluteFill } from "remotion";

export const Vignette: React.FC = () => (
  <AbsoluteFill
    style={{
      background:
        "radial-gradient(ellipse at center, transparent 55%, rgba(0, 0, 0, 0.40) 100%)",
      pointerEvents: "none",
    }}
  />
);
