import React, { useEffect, useState } from "react";
import {
  AbsoluteFill,
  continueRender,
  delayRender,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ANIM, SUBTITLE } from "../../constants";
import type { SubtitleEntry } from "../../types";
import { parseSRT } from "../../utils/srt";

interface SubtitleProps {
  offsetMs?: number; // voiceover start offset in ms
  adjustMs?: number; // fine-tune sync (negative = subs appear earlier)
}

export const Subtitle: React.FC<SubtitleProps> = ({
  offsetMs = 0,
  adjustMs = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const [handle] = useState(() => delayRender("Loading subtitles"));
  const [subs, setSubs] = useState<SubtitleEntry[]>([]);

  useEffect(() => {
    fetch(staticFile("subtitles.srt"))
      .then((r) => r.text())
      .then((t) => {
        setSubs(parseSRT(t));
        continueRender(handle);
      })
      .catch(() => {
        // No subtitle file — continue without subtitles
        continueRender(handle);
      });
  }, [handle]);

  const currentMs = (frame / fps) * 1000 - offsetMs - adjustMs;
  const current = subs.find(
    (s) => currentMs >= s.startMs && currentMs <= s.endMs,
  );

  if (!current) return null;

  // Fade in/out animation
  const fadeMs = (ANIM.subtitleFadeFrames / fps) * 1000;
  const opacity = Math.min(
    interpolate(
      currentMs,
      [current.startMs, current.startMs + fadeMs],
      [0, 1],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    ),
    interpolate(
      currentMs,
      [current.endMs - fadeMs, current.endMs],
      [1, 0],
      { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
    ),
  );

  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          bottom: `${SUBTITLE.bottomOffset * 100}%`,
          width: "100%",
          display: "flex",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            backgroundColor: SUBTITLE.bgColor,
            color: SUBTITLE.textColor,
            fontFamily: SUBTITLE.fontFamily,
            fontSize: SUBTITLE.fontSize,
            paddingLeft: SUBTITLE.paddingX,
            paddingRight: SUBTITLE.paddingX,
            paddingTop: SUBTITLE.paddingY,
            paddingBottom: SUBTITLE.paddingY,
            borderRadius: SUBTITLE.borderRadius,
            maxWidth: "80%",
            textAlign: "center",
            lineHeight: 1.4,
            opacity,
          }}
        >
          {current.text}
        </div>
      </div>
    </AbsoluteFill>
  );
};
