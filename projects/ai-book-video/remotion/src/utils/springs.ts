import type { SpringConfig } from "remotion";

export const SPRINGS: Record<string, SpringConfig> = {
  kenBurns: { damping: 200, stiffness: 10, mass: 1, overshootClamping: false },
  transition: { damping: 40, stiffness: 120, mass: 0.8, overshootClamping: false },
  subtitleIn: { damping: 30, stiffness: 180, mass: 0.5, overshootClamping: false },
  titleReveal: { damping: 25, stiffness: 80, mass: 1.2, overshootClamping: false },
  introTitle: { damping: 18, stiffness: 60, mass: 1.4, overshootClamping: false },
  introDivider: { damping: 30, stiffness: 100, mass: 0.6, overshootClamping: false },
  chapterReveal: { damping: 20, stiffness: 70, mass: 1.0, overshootClamping: false },
  cornerAccent: { damping: 25, stiffness: 90, mass: 0.8, overshootClamping: false },
};
