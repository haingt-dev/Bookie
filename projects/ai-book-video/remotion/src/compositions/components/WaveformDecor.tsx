import React, { useMemo } from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, COLORS, VIDEO, WAVEFORM } from "../../constants";
import { seededRandom } from "../../utils/seededRandom";

interface WaveformDecorProps {
  sceneIndex: number;
}

const BAR_SPACING = 37;
const BAR_MIN = 12;
const BAR_MAX = 180;
const BAR_WIDTH = 5;
const HAZE_DEPTH = 50;
const TWO_PI = Math.PI * 2;
const HARMONICS = [3, 5, 7, 11];
const BASE_AMPLITUDES = [65, 40, 24, 14];
const PEAK_THRESHOLD = BAR_MAX * 0.6;

const TOP_BARS = Math.floor(VIDEO.width / BAR_SPACING);
const RIGHT_BARS = Math.floor(VIDEO.height / BAR_SPACING);
const BOTTOM_BARS = Math.floor(VIDEO.width / BAR_SPACING);
const LEFT_BARS = Math.floor(VIDEO.height / BAR_SPACING);
const TOTAL_BARS = TOP_BARS + RIGHT_BARS + BOTTOM_BARS + LEFT_BARS;

interface BarConfig {
  speeds: number[];
  phases: number[];
}

function generateBarConfig(sceneIndex: number): BarConfig {
  const rand = seededRandom(sceneIndex * 4217);
  return {
    speeds: [0.075, -0.096, 0.126, -0.057].map(
      (s) => s * (0.8 + rand() * 0.4),
    ),
    phases: Array.from({ length: 4 }, () => rand() * TWO_PI),
  };
}

function getBarPosition(
  index: number,
): { x: number; y: number; dx: number; dy: number } {
  if (index < TOP_BARS) {
    const t = (index + 0.5) / TOP_BARS;
    return { x: t * VIDEO.width, y: 0, dx: 0, dy: 1 };
  }
  const i1 = index - TOP_BARS;
  if (i1 < RIGHT_BARS) {
    const t = (i1 + 0.5) / RIGHT_BARS;
    return { x: VIDEO.width, y: t * VIDEO.height, dx: -1, dy: 0 };
  }
  const i2 = i1 - RIGHT_BARS;
  if (i2 < BOTTOM_BARS) {
    const t = 1 - (i2 + 0.5) / BOTTOM_BARS;
    return { x: t * VIDEO.width, y: VIDEO.height, dx: 0, dy: -1 };
  }
  const i3 = i2 - BOTTOM_BARS;
  const t = 1 - (i3 + 0.5) / LEFT_BARS;
  return { x: 0, y: t * VIDEO.height, dx: 1, dy: 0 };
}

export const WaveformDecor: React.FC<WaveformDecorProps> = ({
  sceneIndex,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const config = useMemo(() => generateBarConfig(sceneIndex), [sceneIndex]);

  // Breathing cycle — 8s
  const breathCycle = Math.sin(
    (frame * TWO_PI) / WAVEFORM.breathCycleFrames,
  );
  const amplitudeMod =
    WAVEFORM.breatheMin +
    (WAVEFORM.breatheMax - WAVEFORM.breatheMin) * ((breathCycle + 1) / 2);

  // Fade envelope
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

  const svgId = `wf-${sceneIndex}`;

  // Build bars + peak sparkles
  const bars: React.ReactNode[] = [];
  const peaks: React.ReactNode[] = [];

  for (let i = 0; i < TOTAL_BARS; i++) {
    const angle = (i / TOTAL_BARS) * TWO_PI;

    let harmonicSum = 0;
    for (let h = 0; h < HARMONICS.length; h++) {
      harmonicSum +=
        Math.sin(
          angle * HARMONICS[h] + frame * config.speeds[h] + config.phases[h],
        ) * BASE_AMPLITUDES[h];
    }

    const rawLength = BAR_MIN + (harmonicSum + 143) * amplitudeMod * 0.55;
    const barLength = Math.max(BAR_MIN, Math.min(BAR_MAX, rawLength));

    const { x, y, dx, dy } = getBarPosition(i);
    const x2 = x + dx * barLength;
    const y2 = y + dy * barLength;

    const barOpacity = 0.65 + (barLength / BAR_MAX) * 0.35;
    const color = i % 8 === 0 ? COLORS.primary : COLORS.gold;

    bars.push(
      <line
        key={`b${i}`}
        x1={x}
        y1={y}
        x2={x2}
        y2={y2}
        stroke={color}
        strokeWidth={BAR_WIDTH}
        strokeLinecap="round"
        opacity={barOpacity * fadeEnvelope}
        filter={`url(#${svgId}-neon)`}
      />,
    );

    // Peak sparkle at tip of tall bars
    if (barLength > PEAK_THRESHOLD) {
      peaks.push(
        <circle
          key={`p${i}`}
          cx={x2}
          cy={y2}
          r={2.5}
          fill={COLORS.gold}
          opacity={0.9 * fadeEnvelope}
          filter={`url(#${svgId}-neon)`}
        />,
      );
    }
  }

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <svg
        width={VIDEO.width}
        height={VIDEO.height}
        viewBox={`0 0 ${VIDEO.width} ${VIDEO.height}`}
        style={{ position: "absolute", top: 0, left: 0 }}
      >
        <defs>
          {/* Neon tube glow — sharp inner + wide bloom */}
          <filter id={`${svgId}-neon`} x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceGraphic" stdDeviation={2} result="inner" />
            <feGaussianBlur in="SourceGraphic" stdDeviation={12} result="bloom" />
            <feComponentTransfer in="bloom" result="dimBloom">
              <feFuncA type="linear" slope={0.5} />
            </feComponentTransfer>
            <feMerge>
              <feMergeNode in="dimBloom" />
              <feMergeNode in="inner" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Edge haze gradients */}
          <linearGradient id={`${svgId}-haze-top`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={COLORS.gold} stopOpacity={0.15} />
            <stop offset="100%" stopColor={COLORS.gold} stopOpacity={0} />
          </linearGradient>
          <linearGradient id={`${svgId}-haze-bottom`} x1="0" y1="1" x2="0" y2="0">
            <stop offset="0%" stopColor={COLORS.gold} stopOpacity={0.15} />
            <stop offset="100%" stopColor={COLORS.gold} stopOpacity={0} />
          </linearGradient>
          <linearGradient id={`${svgId}-haze-left`} x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor={COLORS.gold} stopOpacity={0.15} />
            <stop offset="100%" stopColor={COLORS.gold} stopOpacity={0} />
          </linearGradient>
          <linearGradient id={`${svgId}-haze-right`} x1="1" y1="0" x2="0" y2="0">
            <stop offset="0%" stopColor={COLORS.gold} stopOpacity={0.15} />
            <stop offset="100%" stopColor={COLORS.gold} stopOpacity={0} />
          </linearGradient>
        </defs>

        {/* Layer 1: Edge haze strips */}
        <rect x={0} y={0} width={VIDEO.width} height={HAZE_DEPTH}
          fill={`url(#${svgId}-haze-top)`} opacity={fadeEnvelope} />
        <rect x={0} y={VIDEO.height - HAZE_DEPTH} width={VIDEO.width} height={HAZE_DEPTH}
          fill={`url(#${svgId}-haze-bottom)`} opacity={fadeEnvelope} />
        <rect x={0} y={0} width={HAZE_DEPTH} height={VIDEO.height}
          fill={`url(#${svgId}-haze-left)`} opacity={fadeEnvelope} />
        <rect x={VIDEO.width - HAZE_DEPTH} y={0} width={HAZE_DEPTH} height={VIDEO.height}
          fill={`url(#${svgId}-haze-right)`} opacity={fadeEnvelope} />

        {/* Layer 2: Spectrum bars */}
        {bars}

        {/* Layer 3: Peak sparkles */}
        {peaks}
      </svg>
    </AbsoluteFill>
  );
};
