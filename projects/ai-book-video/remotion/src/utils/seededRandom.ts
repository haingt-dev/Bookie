// Mulberry32 — fast, deterministic 32-bit PRNG
// Use: const rand = seededRandom(sceneIndex * 7919); rand() → 0..1
export function seededRandom(seed: number): () => number {
  let t = seed + 0x6d2b79f5;
  return () => {
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
