#!/usr/bin/env node
/**
 * create-form.mjs — tạo form đăng ký per-event + QR, ghi ngược vào event.json
 *
 * Dùng:
 *   node create-form.mjs --data ../../projects/<event>/assets/event.json
 *   node create-form.mjs --data <event.json> --dry-run     # xem payload, không gọi
 *   node create-form.mjs --data <event.json> --qr-only     # chỉ sinh lại QR từ link đã có
 *   node create-form.mjs --data <event.json> --force       # tạo form MỚI dù đã có link cũ
 *   node create-form.mjs --new-proposal "BT31"              # copy Doc proposal cho kỳ mới
 *                                                            (host điền bản copy này)
 *
 * Cơ chế:
 *   - POST event data + secret tới Apps Script Web App (account bookie) —
 *     endpoint clone form gốc, sửa nội dung, trả link. Xem README.md + apps-script/.
 *   - Ghi ngược event.json: dang_ky (forms.gle), form_edit_url, form_published_url,
 *     calendar_link (build local, không cần API), qr.
 *   - Sinh QR encode link DÀI (published_url — không phụ thuộc shortener):
 *     SVG (vendored lib/qrcode.js, MIT) + PNG 1200px (headless Chrome, như render.mjs).
 *   - Env: BOOKIE_FORM_WEBAPP_URL + BOOKIE_FORM_SECRET từ Bookie/.env (gitignored).
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(ROOT, "..", "..");
const qrcode = createRequire(import.meta.url)("./lib/qrcode.js");

// ---------- args ----------
const args = process.argv.slice(2);
function argOf(flag, fallback = null) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] && !args[i + 1].startsWith("--") ? args[i + 1] : fallback;
}
const dataPath = argOf("--data");
const dryRun = args.includes("--dry-run");
const qrOnly = args.includes("--qr-only");
const force = args.includes("--force");
const newProposalKy = argOf("--new-proposal");

if (!dataPath && !newProposalKy) {
  console.error("Cần --data <event.json> hoặc --new-proposal <tên kỳ>. Xem header file này.");
  process.exit(1);
}
const dataAbs = dataPath ? path.resolve(dataPath) : null;
const data = dataAbs ? JSON.parse(fs.readFileSync(dataAbs, "utf8")) : null;

// ---------- env (.env ở repo root, gitignored) ----------
function loadEnv() {
  const envPath = path.join(REPO, ".env");
  const out = {};
  if (fs.existsSync(envPath)) {
    for (const line of fs.readFileSync(envPath, "utf8").split("\n")) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m && !line.trim().startsWith("#")) out[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
  }
  return { ...out, ...process.env };
}
const env = loadEnv();

// ---------- calendar link (URL template — không cần Calendar API) ----------
function toCalDate(s) {
  // "2026-07-27T09:00" | "2026-07-27T09:00:00" → "20260727T090000"
  const m = String(s).match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$/);
  if (!m) return null;
  return `${m[1]}${m[2]}${m[3]}T${m[4]}${m[5]}${m[6] || "00"}`;
}
function buildCalendarLink(d) {
  const iso = d.ngay_gio_iso || {};
  const start = toCalDate(iso.start);
  const end = toCalDate(iso.end) || start;
  if (!start) return null;
  const q = new URLSearchParams({
    action: "TEMPLATE",
    text: `${d.loai_event}: ${d.ten_sach}`,
    dates: `${start}/${end}`,
    ctz: "Asia/Ho_Chi_Minh",
    location: d.dia_diem || "",
    details: d.chu_de || "",
  });
  return `https://calendar.google.com/calendar/render?${q.toString()}`;
}

// ---------- QR (SVG vendored lib + PNG qua Chrome) ----------
function makeQr(url, destDir) {
  const qr = qrcode(0, "M"); // version tự động, error correction M
  qr.addData(url);
  qr.make();
  const n = qr.getModuleCount();

  const svgPath = path.join(destDir, "qr-dang-ky.svg");
  fs.writeFileSync(svgPath, qr.createSvgTag(8, 32)); // cell 8px, quiet zone 4 module

  // PNG ~1200px cho slide/in ấn — screenshot SVG bằng Chrome (như render.mjs)
  const pngPath = path.join(destDir, "qr-dang-ky.png");
  const cell = Math.max(16, Math.round(1200 / (n + 8)));
  const size = n * cell + 2 * cell * 4;
  const bigSvgPath = path.join(destDir, "_qr-big.svg");
  fs.writeFileSync(bigSvgPath, qr.createSvgTag(cell, cell * 4));
  const chrome =
    env.CHROME_BIN ||
    ["/usr/bin/google-chrome-stable", "/usr/bin/chromium", "/usr/bin/chromium-browser"].find((p) => fs.existsSync(p));
  if (chrome) {
    execFileSync(
      chrome,
      ["--headless=new", "--disable-gpu", "--hide-scrollbars", `--window-size=${size},${size}`,
        `--screenshot=${pngPath}`, pathToFileURL(bigSvgPath).href],
      { stdio: ["ignore", "ignore", "pipe"] }
    );
    console.log(`✔ QR PNG  → ${pngPath} (${size}×${size})`);
  } else {
    console.warn("⚠ Không tìm thấy Chrome — bỏ qua bản PNG (SVG vẫn đủ cho poster).");
  }
  fs.rmSync(bigSvgPath, { force: true });
  console.log(`✔ QR SVG  → ${svgPath} (${n} modules, EC M)`);
  return path.basename(svgPath);
}

// ---------- main ----------
if (newProposalKy) {
  if (dryRun) {
    console.log(`— dry-run: sẽ copy Doc proposal cho kỳ "${newProposalKy}" vào Bookie 2026/Proposals/ —`);
    process.exit(0);
  }
  const webappUrl = env.BOOKIE_FORM_WEBAPP_URL;
  const secret = env.BOOKIE_FORM_SECRET;
  if (!webappUrl || !secret) {
    console.error("Thiếu BOOKIE_FORM_WEBAPP_URL / BOOKIE_FORM_SECRET trong Bookie/.env — xem README.md (mục Deploy).");
    process.exit(1);
  }
  const res = await fetch(webappUrl, {
    method: "POST",
    headers: { "Content-Type": "text/plain" },
    body: JSON.stringify({ action: "new_proposal", ky: newProposalKy, secret }),
    redirect: "follow",
  });
  const text = await res.text();
  let result;
  try {
    result = JSON.parse(text);
  } catch {
    console.error(`Endpoint không trả JSON (HTTP ${res.status}). Đầu response:\n${text.slice(0, 300)}`);
    process.exit(2);
  }
  if (!result.ok) {
    console.error(`Endpoint báo lỗi: ${result.error}`);
    process.exit(2);
  }
  console.log(result.existed ? `✔ Kỳ ${newProposalKy} đã có proposal từ trước:` : `✔ Proposal mới cho kỳ ${newProposalKy}:`);
  console.log(`  ${result.proposal_url}`);
  console.log("→ Gửi link cho đầu mối nhóm host điền trực tiếp trên Doc.");
  process.exit(0);
}

const calendarLink = buildCalendarLink(data);
if (!calendarLink) {
  console.warn('⚠ Thiếu/sai "ngay_gio_iso": {"start":"YYYY-MM-DDTHH:MM","end":"…"} — bỏ qua calendar link.');
}

if (qrOnly) {
  const url = data.form_published_url;
  if (!url) {
    console.error("event.json chưa có form_published_url — chạy không --qr-only để tạo form trước.");
    process.exit(1);
  }
  if (dryRun) {
    console.log(`— dry-run: sẽ sinh QR (EC M) encode ${url} → ${path.dirname(dataAbs)}/qr-dang-ky.{svg,png} —`);
    process.exit(0);
  }
  data.qr = makeQr(url, path.dirname(dataAbs));
  fs.writeFileSync(dataAbs, JSON.stringify(data, null, 2) + "\n");
  process.exit(0);
}

if (data.form_published_url && !force) {
  console.error(
    `event.json đã có form: ${data.form_published_url}\n` +
      "→ Tránh tạo form trùng. Dùng --qr-only để sinh lại QR, hoặc --force nếu thật sự muốn form MỚI."
  );
  process.exit(1);
}

const payload = {
  ten_sach: data.ten_sach,
  loai_event: data.loai_event,
  ngay_gio: data.ngay_gio,
  ngay_gio_iso: data.ngay_gio_iso,
  dia_diem: data.dia_diem,
  chu_de: data.chu_de,
  dien_gia: data.dien_gia,
  calendar_link: calendarLink,
  // --force với event đã có lịch: gửi id cũ để endpoint xoá, tránh trùng calendar
  replace_calendar_event_id: force ? data.calendar_event_id : undefined,
};

if (dryRun) {
  console.log("— dry-run: payload sẽ gửi (chưa kèm secret) —");
  console.log(JSON.stringify(payload, null, 2));
  process.exit(0);
}

const webappUrl = env.BOOKIE_FORM_WEBAPP_URL;
const secret = env.BOOKIE_FORM_SECRET;
if (!webappUrl || !secret) {
  console.error("Thiếu BOOKIE_FORM_WEBAPP_URL / BOOKIE_FORM_SECRET trong Bookie/.env — xem README.md (mục Deploy).");
  process.exit(1);
}

const res = await fetch(webappUrl, {
  method: "POST",
  headers: { "Content-Type": "text/plain" }, // tránh CORS preflight với Apps Script
  body: JSON.stringify({ ...payload, secret }),
  redirect: "follow", // Apps Script trả 302 → script.googleusercontent.com
});
const text = await res.text();
let result;
try {
  result = JSON.parse(text);
} catch {
  console.error(`Endpoint không trả JSON (HTTP ${res.status}). Đầu response:\n${text.slice(0, 300)}`);
  process.exit(2);
}
if (!result.ok) {
  console.error(`Endpoint báo lỗi: ${result.error}`);
  process.exit(2);
}

// ghi ngược event.json — dang_ky hiển thị dạng ngắn không protocol
data.dang_ky = result.short_url.replace(/^https?:\/\//, "");
data.form_edit_url = result.edit_url;
data.form_published_url = result.published_url;
if (calendarLink) data.calendar_link = calendarLink;
if (result.calendar_event_id) data.calendar_event_id = result.calendar_event_id;
data.qr = makeQr(result.published_url, path.dirname(dataAbs));
fs.writeFileSync(dataAbs, JSON.stringify(data, null, 2) + "\n");

console.log(`✔ Form     → ${result.edit_url}`);
console.log(`✔ Đăng ký  → ${result.short_url}`);
console.log(`✔ Folder   → ${result.folder_url}`);
if (result.calendar_event_id) console.log(`✔ Calendar → đã lên lịch trên "Bookie Events"`);
if (result.calendar_error) console.warn(`⚠ Calendar lỗi (form vẫn OK): ${result.calendar_error}`);
console.log(`✔ event.json đã cập nhật: dang_ky, form_edit_url, form_published_url, calendar_link${result.calendar_event_id ? ", calendar_event_id" : ""}, qr`);
