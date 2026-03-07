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
import { ANIM, BRAND_BAR, SUBTITLE } from "../../constants";
import type { SubtitleEntry } from "../../types";
import { parseSRT } from "../../utils/srt";

interface SubtitleProps {
  offsetMs?: number;
  adjustMs?: number;
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
      .then((r) => {
        if (!r.ok) {
          throw new Error(`Subtitle fetch failed: ${r.status} ${r.statusText}`);
        }
        return r.text();
      })
      .then((t) => {
        const parsed = parseSRT(t);
        console.log(`[Subtitle] Loaded ${parsed.length} entries`);
        setSubs(parsed);
        continueRender(handle);
      })
      .catch((err) => {
        console.error("[Subtitle] Failed to load subtitles:", err);
        continueRender(handle);
      });
  }, [handle]);

  const currentMs = (frame / fps) * 1000 - offsetMs - adjustMs;
  const current = subs.find(
    (s) => currentMs >= s.startMs && currentMs <= s.endMs,
  );

  if (!current) return null;

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

  // Position above BrandBar
  const bottomPx = SUBTITLE.bottomPx + BRAND_BAR.height + BRAND_BAR.progressHeight;

  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          bottom: bottomPx,
          width: "100%",
          display: "flex",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "stretch",
            maxWidth: SUBTITLE.maxWidth,
            opacity,
            backdropFilter: "blur(10px)",
            boxShadow: "0 4px 16px rgba(0, 0, 0, 0.2)",
            borderRadius: SUBTITLE.borderRadius,
          }}
        >
          {/* Green accent bar with glow */}
          <div
            style={{
              width: SUBTITLE.accentWidth,
              backgroundColor: SUBTITLE.accentColor,
              borderRadius: `${SUBTITLE.borderRadius}px 0 0 ${SUBTITLE.borderRadius}px`,
              flexShrink: 0,
              boxShadow: "2px 0 12px rgba(27, 107, 42, 0.3)",
            }}
          />
          {/* Text pill */}
          <div
            style={{
              backgroundColor: SUBTITLE.bgColor,
              color: SUBTITLE.textColor,
              fontFamily: SUBTITLE.fontFamily,
              fontSize: SUBTITLE.fontSize,
              fontWeight: 500,
              paddingLeft: SUBTITLE.paddingX,
              paddingRight: SUBTITLE.paddingX,
              paddingTop: SUBTITLE.paddingY,
              paddingBottom: SUBTITLE.paddingY,
              borderRadius: `0 ${SUBTITLE.borderRadius}px ${SUBTITLE.borderRadius}px 0`,
              textAlign: "left",
              lineHeight: 1.4,
              textShadow: "0 1px 3px rgba(0, 0, 0, 0.3)",
            }}
          >
            {current.text}
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
