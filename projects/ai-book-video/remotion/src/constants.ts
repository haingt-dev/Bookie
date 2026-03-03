// Brand colors from shared/branding/Bookie Branding Guideline.md
export const COLORS = {
  primary: "#368C06",
  secondary: "#4AC808",
  accent: "#C86108",
  background: "#FAFDF5",
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

// Subtitle config
export const SUBTITLE = {
  fontFamily: "Be Vietnam Pro",
  fontSize: 38,
  bottomOffset: 0.1, // 10% from bottom
  bgColor: "rgba(0, 0, 0, 0.6)",
  textColor: COLORS.white,
  paddingX: 20,
  paddingY: 8,
  borderRadius: 8,
} as const;

// Audio
export const BGM_VOLUME = 0.5;
export const BGM_AMBIENT = 0.12;

// Animation defaults
export const ANIM = {
  fadeFrames: 15,
  kenBurnsScale: 1.05,
  logoOpacity: 0.7,
} as const;
