/**
 * form-dang-ky.gs — endpoint tạo form đăng ký per-event cho Bookie.
 *
 * Deploy MỘT LẦN trên account bookie.community@gmail.com dưới dạng Web App
 * (Execute as: Me · Access: Anyone) — hướng dẫn từng bước: ../README.md.
 *
 * SECRET KHÔNG nằm trong file này. Toàn bộ config đặt ở Script Properties:
 *   SECRET            — chuỗi ngẫu nhiên, khớp BOOKIE_FORM_SECRET trong Bookie/.env
 *   TEMPLATE_ID       — id form gốc "Format Form đăng ký" (Bookie 2026/Templates/)
 *   EVENTS_FOLDER_ID  — id folder "Bookie 2026/Events/"
 *
 * Nguyên tắc chống lỗi template-residue: mọi nội dung per-event (title, mô tả,
 * confirmation) CHỈ được ghi từ payload — bộ câu hỏi giữ nguyên theo form gốc.
 */

var PROPS = PropertiesService.getScriptProperties();

function doGet() {
  // smoke-test: mở URL web app trên browser phải thấy JSON này
  return jsonOut({ ok: true, service: "bookie-form-dang-ky", usage: "POST JSON — xem shared/event-automation/README.md" });
}

function doPost(e) {
  try {
    var body = JSON.parse((e && e.postData && e.postData.contents) || "{}");

    // Web App không set được HTTP status code → báo lỗi qua field ok/error
    if (!body.secret || body.secret !== PROPS.getProperty("SECRET")) {
      return jsonOut({ ok: false, error: "sai hoặc thiếu secret" });
    }
    var required = ["ten_sach", "loai_event", "ngay_gio", "dia_diem"];
    var missing = required.filter(function (k) { return !body[k]; });
    if (missing.length) {
      return jsonOut({ ok: false, error: "thiếu field: " + missing.join(", ") });
    }

    // 1. Folder per-event dưới Events/ — tìm theo tên, chưa có thì tạo
    var eventsRoot = DriveApp.getFolderById(PROPS.getProperty("EVENTS_FOLDER_ID"));
    var folderName = eventFolderName(body);
    var found = eventsRoot.getFoldersByName(folderName);
    var folder = found.hasNext() ? found.next() : eventsRoot.createFolder(folderName);

    // 2. Clone form gốc vào folder event (giữ nguyên theme/ảnh header/bộ câu hỏi)
    var formTitle = "Đăng ký " + body.loai_event.toUpperCase() + ": " + body.ten_sach.toUpperCase();
    var copy = DriveApp.getFileById(PROPS.getProperty("TEMPLATE_ID")).makeCopy(formTitle, folder);
    var form = FormApp.openById(copy.getId());

    // 3. Nội dung per-event
    form.setTitle(formTitle);
    form.setDescription(buildDescription(body));
    form.setConfirmationMessage(buildConfirmation(body));
    form.setAcceptingResponses(true);

    // 4. Publish guard — sau cutover 30/06/2026 form tạo mới có thể mặc định
    //    unpublished; docs không nói rõ trường hợp copy → tự check cho chắc
    try {
      if (typeof form.isPublished === "function" && !form.isPublished()) {
        form.setPublished(true);
      }
    } catch (errPublish) {
      // form theo model cũ không có isPublished → đã nhận response sẵn, bỏ qua
    }

    var publishedUrl = form.getPublishedUrl();
    var shortUrl;
    try {
      shortUrl = form.shortenFormUrl(publishedUrl); // https://forms.gle/…
    } catch (errShort) {
      shortUrl = publishedUrl; // không rút gọn được thì trả link dài
    }

    return jsonOut({
      ok: true,
      form_id: form.getId(),
      edit_url: form.getEditUrl(),
      published_url: publishedUrl,
      short_url: shortUrl,
      folder_url: folder.getUrl(),
    });
  } catch (err) {
    return jsonOut({ ok: false, error: String(err) });
  }
}

/** "2026-07 Book!e Discussion — Tên sách" (YYYY-MM lấy từ ngay_gio_iso.start nếu có) */
function eventFolderName(body) {
  var ym = "";
  var start = body.ngay_gio_iso && body.ngay_gio_iso.start;
  if (start && /^\d{4}-\d{2}/.test(start)) ym = start.slice(0, 7) + " ";
  return ym + body.loai_event + " — " + body.ten_sach;
}

function buildDescription(body) {
  var lines = [];
  if (body.chu_de) lines.push(body.chu_de, "");
  lines.push("🕘 " + body.ngay_gio);
  lines.push("📍 " + body.dia_diem);
  if (body.dien_gia) lines.push("🎤 " + body.dien_gia);
  lines.push("", "Điền form để giữ chỗ — Book!e sẽ xác nhận và nhắc lịch qua email trước sự kiện.");
  return lines.join("\n");
}

function buildConfirmation(body) {
  var lines = [
    "Cảm ơn bạn đã đăng ký " + body.loai_event + ": " + body.ten_sach + "!",
    "Hẹn gặp bạn lúc " + body.ngay_gio + " tại " + body.dia_diem + ".",
  ];
  if (body.calendar_link) lines.push("", "Thêm vào Google Calendar để khỏi quên: " + body.calendar_link);
  lines.push("", "Book!e Inspires Everyone — fb.com/bookie.community");
  return lines.join("\n");
}

function jsonOut(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
