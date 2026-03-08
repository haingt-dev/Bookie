// Brand colors — premium editorial design system
export const COLORS = {
  primary: "#1B6B2A",
  secondary: "#4CAF50",
  accent: "#B8860B",
  gold: "#D4A853",
  background: "#FAFDF5",
  sage: "#EEF2EB",
  ink: "#1A2318",
  textDark: "#2D3436",
  textLight: "#636E72",
  white: "#FFFFFF",
} as const;

// Video specs
export const VIDEO = {
  width: 1920,
  height: 1080,
  fps: 30,
} as const;

export const SHORT = {
  width: 1080,
  height: 1920,
  fps: 30,
} as const;

// Subtitle config — cinematic editorial style
export const SUBTITLE = {
  fontFamily: "Be Vietnam Pro",
  fontSize: 34,
  bottomPx: 80,
  bgColor: "rgba(10, 15, 10, 0.72)",
  textColor: COLORS.white,
  accentColor: COLORS.primary,
  accentWidth: 5,
  paddingX: 24,
  paddingY: 14,
  borderRadius: 6,
  maxWidth: "75%",
} as const;

// Audio
export const BGM_VOLUME = 0.5;
export const BGM_AMBIENT = 0.12;

// Animation defaults
export const ANIM = {
  fadeFrames: 15,
  kenBurnsScale: 1.1,
  kenBurnsPanPx: 35,
  subtitleFadeFrames: 5,
  sceneTitleDurationS: 3.5,
} as const;

// BrandBar — premium persistent bottom bar
export const BRAND_BAR = {
  height: 56,
  logoHeight: 28,
  paddingX: 30,
  dotSize: 6,
  dotGap: 10,
  progressHeight: 4,
  bgColor: "rgba(10, 15, 10, 0.7)",
  fontSize: 13,
  glowColor: "rgba(27, 107, 42, 0.6)",
} as const;

// Framed layout (editorial) — sage margins with depth
export const FRAME = {
  padding: 48,
  borderRadius: 16,
  shadow: "0 8px 32px rgba(0, 0, 0, 0.15)",
} as const;

// Intro/Outro — decorative elements
export const INTRO = {
  dividerWidth: 80,
  dividerHeight: 2,
  warmGlow:
    "radial-gradient(ellipse at 50% 40%, rgba(212, 168, 83, 0.06) 0%, transparent 70%)",
} as const;

// Ambient particles — floating bokeh
export const AMBIENT = {
  count: 18,
  sizeMin: 3,
  sizeMax: 10,
  opacityMin: 0.02,
  opacityMax: 0.06,
  blurMin: 2,
  blurMax: 6,
  amplitudeX: [20, 60] as const,
  amplitudeY: [15, 40] as const,
  freqX: [0.003, 0.008] as const,
  freqY: [0.002, 0.006] as const,
} as const;

// Light leak — cinematic anamorphic artifact
export const LIGHT_LEAK = {
  blurPx: 60,
  presets: [
    { color: "rgba(212, 168, 83, 0.05)", startX: -20, startY: 10, endX: 120, endY: 70, angle: 15 },
    { color: "rgba(27, 107, 42, 0.04)", startX: 110, startY: 20, endX: -10, endY: 80, angle: -20 },
    { color: "rgba(212, 168, 83, 0.06)", startX: -10, startY: 90, endX: 110, endY: 30, angle: 10 },
    { color: "rgba(76, 175, 80, 0.04)", startX: 100, startY: 50, endX: 0, endY: 50, angle: 0 },
  ],
} as const;

// Corner accents — editorial bracket decorations
export const CORNER = {
  lineWidth: 2,
  lineLength: 40,
  dotRadius: 2,
  insetBleed: 32,
  insetFramed: 16,
  breatheFreq: 0.04,
  breatheBase: 0.22,
  breatheAmp: 0.05,
} as const;

// Waveform — circular audio visualizer
export const WAVEFORM = {
  breathCycleFrames: 240,
  breatheMin: 0.6,
  breatheMax: 1.0,
} as const;

// Audio spectrum — bottom-center reactive visualizer
export const AUDIO_SPECTRUM = {
  barCount: 40,
  barWidth: 6,
  barSpacing: 12,
  barMinHeight: 2,
  barMaxHeight: 70,
  bottomY: 68,
  glowStdDev: 8,
  baseOpacity: 0.85,
  breathCycleFrames: 300,
  breathMin: 1.0,
  breathMax: 1.0,
} as const;
