import React, { useEffect, useState } from "react";
import {
  AbsoluteFill,
  continueRender,
  delayRender,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { getAudioData, visualizeAudio } from "@remotion/media-utils";
import type { AudioData } from "@remotion/media-utils";
import { ANIM, AUDIO_SPECTRUM, COLORS, VIDEO } from "../../constants";

interface AudioSpectrumProps {
  audioSrc: string;
}

const TWO_PI = Math.PI * 2;

export const AudioSpectrum: React.FC<AudioSpectrumProps> = ({ audioSrc }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const [audioData, setAudioData] = useState<AudioData | null>(null);
  const [handle] = useState(() =>
    delayRender("Loading audio data for spectrum"),
  );

  useEffect(() => {
    getAudioData(audioSrc)
      .then((data) => {
        setAudioData(data);
        continueRender(handle);
      })
      .catch((err) => {
        console.error("AudioSpectrum: failed to load audio", err);
        continueRender(handle);
      });
  }, [audioSrc, handle]);

  // Breathing cycle
  const breathCycle = Math.sin(
    (frame * TWO_PI) / AUDIO_SPECTRUM.breathCycleFrames,
  );
  const breathMod =
    AUDIO_SPECTRUM.breathMin +
    (AUDIO_SPECTRUM.breathMax - AUDIO_SPECTRUM.breathMin) *
      ((breathCycle + 1) / 2);

  // Fade envelope — match scene cross-dissolve timing
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

  // Get frequency data — numberOfSamples must be power of two
  const FFT_SIZE = 32;
  const rawVisualization = audioData
    ? visualizeAudio({
        fps,
        frame,
        audioData,
        numberOfSamples: FFT_SIZE,
        optimizeFor: "speed",
      })
    : new Array(FFT_SIZE).fill(0);

  const halfBars = AUDIO_SPECTRUM.barCount / 2;

  // Map FFT bins to half the bars
  const halfValues = Array.from({ length: halfBars }, (_, i) => {
    const idx = Math.floor((i / halfBars) * FFT_SIZE);
    return rawVisualization[idx];
  });

  // Mirror (center = low freq, edges = high freq) + cosine taper
  const visualization = Array.from(
    { length: AUDIO_SPECTRUM.barCount },
    (_, i) => {
      const mirrorIdx = i < halfBars ? halfBars - 1 - i : i - halfBars;
      const value = halfValues[mirrorIdx];
      const t = Math.abs((2 * i) / (AUDIO_SPECTRUM.barCount - 1) - 1);
      const taper = 0.3 + 0.7 * Math.cos((Math.PI / 2) * t);
      return value * taper;
    },
  );

  // Layout — centered horizontally
  const totalWidth =
    AUDIO_SPECTRUM.barCount * AUDIO_SPECTRUM.barSpacing;
  const startX = (VIDEO.width - totalWidth) / 2;

  const filterId = "audio-spectrum-glow";

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <svg
        width={VIDEO.width}
        height={VIDEO.height}
        viewBox={`0 0 ${VIDEO.width} ${VIDEO.height}`}
        style={{ position: "absolute", top: 0, left: 0 }}
      >
        <defs>
          <filter
            id={filterId}
            x="-50%"
            y="-50%"
            width="200%"
            height="200%"
          >
            <feGaussianBlur
              in="SourceGraphic"
              stdDeviation={2}
              result="inner"
            />
            <feGaussianBlur
              in="SourceGraphic"
              stdDeviation={AUDIO_SPECTRUM.glowStdDev}
              result="bloom"
            />
            <feComponentTransfer in="bloom" result="dimBloom">
              <feFuncA type="linear" slope={0.4} />
            </feComponentTransfer>
            <feMerge>
              <feMergeNode in="dimBloom" />
              <feMergeNode in="inner" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {visualization.map((value: number, i: number) => {
          // Power curve — amplify peaks for dramatic jumps
          const boosted = Math.pow(value, 0.6) * breathMod;
          const barHeight = interpolate(
            boosted,
            [0, 1],
            [AUDIO_SPECTRUM.barMinHeight, AUDIO_SPECTRUM.barMaxHeight],
            { extrapolateRight: "clamp" },
          );

          const x = startX + i * AUDIO_SPECTRUM.barSpacing + AUDIO_SPECTRUM.barSpacing / 2;
          // Bars grow upward from bottom
          const y1 = VIDEO.height - AUDIO_SPECTRUM.bottomY;
          const y2 = y1 - barHeight;

          const barOpacity =
            AUDIO_SPECTRUM.baseOpacity + boosted * 0.15;
          const op = barOpacity * fadeEnvelope;

          return (
            <React.Fragment key={i}>
              {/* Dark outline — visible on bright backgrounds */}
              <line
                x1={x}
                y1={y1}
                x2={x}
                y2={y2}
                stroke="rgba(27, 107, 42, 0.35)"
                strokeWidth={AUDIO_SPECTRUM.barWidth + 1}
                strokeLinecap="round"
                opacity={fadeEnvelope}
              />
              {/* White bar with glow */}
              <line
                x1={x}
                y1={y1}
                x2={x}
                y2={y2}
                stroke={COLORS.white}
                strokeWidth={AUDIO_SPECTRUM.barWidth}
                strokeLinecap="round"
                opacity={op}
                filter={`url(#${filterId})`}
              />
            </React.Fragment>
          );
        })}
      </svg>
    </AbsoluteFill>
  );
};
