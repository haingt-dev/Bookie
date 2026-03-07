import { Config } from "@remotion/cli/config";

// YouTube-optimal render defaults (1080p30 H.264)
Config.setCodec("h264");
Config.setCrf(18); // High quality source — YouTube re-encodes
Config.setPixelFormat("yuv420p"); // Required for broad compatibility

Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);

// Performance: GPU-accelerated frame rendering (NVIDIA on Linux)
Config.setChromiumOpenGlRenderer("angle-egl");

// Performance: auto-detect optimal thread count (50% of CPU threads)
Config.setConcurrency(null);
