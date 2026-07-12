#!/usr/bin/env node
/**
 * render.mjs — render template + data.json → PNG đúng khổ (headless Chrome)
 *
 * Dùng:
 *   node render.mjs --template poster-feed --data templates/poster-feed/data.sample.json
 *   node render.mjs --template cover-event --data <event.json> --out /path/den/cover.png
 *   node render.mjs --template cover-event --data <event.json> --debug-safe-area
 *
 * Cơ chế:
 *   - Đọc templates/<name>/config.json  → { width, height, safe? }
 *   - Thế {{key}} trong template.html bằng data (HTML-escaped);
 *     section {{#key}}...{{/key}} giữ lại khi data[key] khác rỗng, ngược lại xoá.
 *   - Trường "bg" trong data = đường dẫn ảnh nền (tương đối so với file data);
 *     được resolve thành file:// URL, expose thêm {{bg_url}} + section {{#bg}}.
 *   - Trường "qr" tương tự → {{qr_url}} + section {{#qr}} (QR đăng ký trên poster,
 *     sinh bởi shared/event-automation/create-form.mjs).
 *   - Ghi _composed.html cạnh template.html (gitignored) rồi chụp bằng
 *     google-chrome-stable --headless=new --screenshot.
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const CHROME =
  process.env.CHROME_BIN ||
  ["/usr/bin/google-chrome-stable", "/usr/bin/chromium", "/usr/bin/chromium-browser"].find(
    (p) => fs.existsSync(p)
  );

// ---------- args ----------
const args = process.argv.slice(2);
function argOf(flag, fallback = null) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] && !args[i + 1].startsWith("--") ? args[i + 1] : fallback;
}
const templateName = argOf("--template");
const dataPath = argOf("--data");
const outArg = argOf("--out");
const scale = Number(argOf("--scale", "1"));
const debugSafe = args.includes("--debug-safe-area");

if (!templateName || !dataPath) {
  console.error("Cần --template <tên> và --data <file.json>. Xem header file này.");
  process.exit(1);
}
if (!CHROME) {
  console.error("Không tìm thấy Chrome/Chromium. Set CHROME_BIN=<đường dẫn>.");
  process.exit(1);
}

const tplDir = path.join(ROOT, "templates", templateName);
const config = JSON.parse(fs.readFileSync(path.join(tplDir, "config.json"), "utf8"));
const data = JSON.parse(fs.readFileSync(dataPath, "utf8"));

// ---------- compose ----------
let html = fs.readFileSync(path.join(tplDir, "template.html"), "utf8");

const escapeHtml = (s) =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// bg: resolve tương đối so với file data → file:// URL
const view = { ...data };
if (data.bg && String(data.bg).trim() !== "") {
  const bgAbs = path.resolve(path.dirname(path.resolve(dataPath)), data.bg);
  if (!fs.existsSync(bgAbs)) {
    console.error(`Ảnh nền không tồn tại: ${bgAbs}`);
    process.exit(1);
  }
  view.bg_url = pathToFileURL(bgAbs).href;
} else {
  view.bg = "";
}

// qr: cùng cơ chế với bg
if (data.qr && String(data.qr).trim() !== "") {
  const qrAbs = path.resolve(path.dirname(path.resolve(dataPath)), data.qr);
  if (!fs.existsSync(qrAbs)) {
    console.error(`Ảnh QR không tồn tại: ${qrAbs}`);
    process.exit(1);
  }
  view.qr_url = pathToFileURL(qrAbs).href;
} else {
  view.qr = "";
}

// sections {{#key}}...{{/key}} — giữ khi truthy/khác rỗng
html = html.replace(/\{\{#([\w]+)\}\}([\s\S]*?)\{\{\/\1\}\}/g, (_, key, body) =>
  view[key] && String(view[key]).trim() !== "" ? body : ""
);
// biến {{key}} — bg_url/qr_url giữ nguyên (là URL), còn lại escape
html = html.replace(/\{\{([\w]+)\}\}/g, (_, key) => {
  const v = view[key];
  if (v === undefined || v === null) return "";
  return key === "bg_url" || key === "qr_url" ? String(v) : escapeHtml(v);
});

// overlay safe zone (tune template cover: vùng luôn hiển thị mọi thiết bị)
if (debugSafe && config.safe) {
  const { top = 0, right = 0, bottom = 0, left = 0, label = "SAFE" } = config.safe;
  html = html.replace(
    "</body>",
    `<div style="position:fixed;top:${top}px;right:${right}px;bottom:${bottom}px;left:${left}px;
      border:4px dashed #ff00aa;z-index:9999;display:flex;align-items:flex-start;justify-content:flex-end;">
      <span style="background:#ff00aa;color:#fff;font:700 24px sans-serif;padding:4px 12px;">${label}</span>
    </div></body>`
  );
}

const composedPath = path.join(tplDir, "_composed.html");
fs.writeFileSync(composedPath, html);

// ---------- screenshot ----------
const slug = (data.ten_sach || data.chu_de || "event")
  .toLowerCase()
  .normalize("NFD")
  .replace(/[̀-ͯ]/g, "")
  .replace(/đ/g, "d")
  .replace(/[^a-z0-9]+/g, "-")
  .replace(/(^-|-$)/g, "")
  .slice(0, 40);

let outPath = outArg
  ? path.resolve(outArg)
  : path.join(ROOT, "out", `${templateName}--${slug}.png`);
if (outArg && (fs.existsSync(outPath) ? fs.statSync(outPath).isDirectory() : !path.extname(outPath))) {
  fs.mkdirSync(outPath, { recursive: true });
  outPath = path.join(outPath, `${templateName}--${slug}.png`);
}
fs.mkdirSync(path.dirname(outPath), { recursive: true });

execFileSync(
  CHROME,
  [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    `--force-device-scale-factor=${scale}`,
    `--window-size=${config.width},${config.height}`,
    "--virtual-time-budget=5000",
    `--screenshot=${outPath}`,
    pathToFileURL(composedPath).href,
  ],
  { stdio: ["ignore", "ignore", "pipe"] }
);

if (!fs.existsSync(outPath)) {
  console.error("Chrome không xuất được screenshot.");
  process.exit(2);
}
console.log(`✔ ${templateName} → ${outPath} (${config.width * scale}×${config.height * scale})`);
