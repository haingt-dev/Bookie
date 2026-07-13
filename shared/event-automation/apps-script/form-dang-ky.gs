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
 *   CALENDAR_ID       — (tùy chọn) id calendar "Bookie Events" — có thì mỗi event
 *                       được tạo thêm trên calendar này (nguồn cho embed website)
 *   PROPOSAL_TEMPLATE_ID — (tùy chọn) id Doc "[Template] Proposal BT (2026)"
 *   PROPOSALS_FOLDER_ID  — (tùy chọn) id folder "Bookie 2026/Proposals/"
 *                       → bật action "new_proposal": copy template proposal cho kỳ mới
 *
 * Setup one-time: chạy tay setupTemplateForm() + setupEventsCalendar() từ editor
 * (Run ▸ chọn hàm) để tự dựng form gốc + calendar — xem hướng dẫn ../README.md.
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

    // Action phụ: copy template proposal cho kỳ mới (host điền trên bản copy này)
    if (body.action === "new_proposal") {
      return newProposal(body);
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

    // 5. Event trên calendar "Bookie Events" (nếu đã cấu hình CALENDAR_ID) —
    //    nguồn dữ liệu cho embed/website; lỗi ở đây KHÔNG chặn luồng chính
    var calendarEventId = null;
    var calendarError = null;
    var calId = PROPS.getProperty("CALENDAR_ID");
    if (calId && body.ngay_gio_iso && body.ngay_gio_iso.start) {
      try {
        // --force rerun: client gửi id event cũ → xoá trước, tránh trùng lịch
        if (body.replace_calendar_event_id) {
          try {
            var oldEvent = CalendarApp.getCalendarById(calId).getEventById(body.replace_calendar_event_id);
            if (oldEvent) oldEvent.deleteEvent();
          } catch (errOld) {
            // event cũ đã bị xoá tay / id lạ — bỏ qua, không chặn
          }
        }
        var startD = parseIsoVn(body.ngay_gio_iso.start);
        var endD = parseIsoVn(body.ngay_gio_iso.end) || new Date(startD.getTime() + 2 * 60 * 60 * 1000);
        var calEvent = CalendarApp.getCalendarById(calId).createEvent(
          body.loai_event + ": " + body.ten_sach,
          startD,
          endD,
          { location: body.dia_diem, description: buildCalendarDescription(body, shortUrl) }
        );
        calendarEventId = calEvent.getId();
      } catch (errCal) {
        calendarError = String(errCal);
      }
    }

    var out = {
      ok: true,
      form_id: form.getId(),
      edit_url: form.getEditUrl(),
      published_url: publishedUrl,
      short_url: shortUrl,
      folder_url: folder.getUrl(),
    };
    if (calendarEventId) out.calendar_event_id = calendarEventId;
    if (calendarError) out.calendar_error = calendarError;
    return jsonOut(out);
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

function buildCalendarDescription(body, dangKyUrl) {
  var lines = [];
  if (body.chu_de) lines.push(body.chu_de, "");
  if (body.dien_gia) lines.push("🎤 " + body.dien_gia);
  lines.push("Đăng ký: " + dangKyUrl);
  lines.push("", "Book!e Inspires Everyone — fb.com/bookie.community");
  return lines.join("\n");
}

/** "2026-08-02T09:00[:ss]" (giờ VN) → Date — gắn offset +07:00 tường minh để không
 *  phụ thuộc timezone của project Apps Script */
function parseIsoVn(s) {
  var m = String(s || "").match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2})(?::\d{2})?$/);
  return m ? new Date(m[1] + ":00+07:00") : null;
}

/** action "new_proposal" — copy Doc template proposal thành bản riêng cho kỳ mới.
 *  Payload: { action: "new_proposal", ky: "BT31" } → bản copy "Proposal - BT31"
 *  trong Bookie 2026/Proposals/, host điền trực tiếp trên đó. */
function newProposal(body) {
  if (!body.ky) return jsonOut({ ok: false, error: 'thiếu "ky" (tên kỳ, vd "BT31")' });
  var templateId = PROPS.getProperty("PROPOSAL_TEMPLATE_ID");
  var folderId = PROPS.getProperty("PROPOSALS_FOLDER_ID");
  if (!templateId || !folderId) {
    return jsonOut({ ok: false, error: "chưa cấu hình PROPOSAL_TEMPLATE_ID / PROPOSALS_FOLDER_ID (Script Properties)" });
  }
  var name = "Proposal - " + body.ky;
  var folder = DriveApp.getFolderById(folderId);
  // chống copy trùng: kỳ này đã có proposal thì trả bản cũ
  var existing = folder.getFilesByName(name);
  if (existing.hasNext()) {
    var old = existing.next();
    return jsonOut({ ok: true, existed: true, proposal_id: old.getId(), proposal_url: old.getUrl() });
  }
  var copy = DriveApp.getFileById(templateId).makeCopy(name, folder);
  return jsonOut({ ok: true, existed: false, proposal_id: copy.getId(), proposal_url: copy.getUrl() });
}

function jsonOut(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

/* ====================================================================
 * SETUP ONE-TIME — chạy tay từ editor (Run ▸ chọn hàm), KHÔNG thuộc Web App.
 * ==================================================================== */

/**
 * Dựng form gốc đúng spec projects/bd-2026/plan/bieu-mau-dang-ky.md rồi chuyển vào
 * Bookie 2026/Templates/. Xem Log (Ctrl+Enter) lấy TEMPLATE_ID điền Script Properties.
 * Sau khi chạy: mở form chỉnh THEME + ảnh header brand bằng UI (~2 phút) —
 * FormApp không set được theme, đó cũng là lý do kiến trúc dùng makeCopy.
 */
function setupTemplateForm() {
  var TEMPLATES_FOLDER_ID = "1jvR--DTWtH7s3x7o9amgMqI88_M_pF6U"; // Bookie 2026/Templates/

  var form = FormApp.create("Format Form đăng ký BD (2026)");
  form.setDescription("(placeholder — automation ghi đè mô tả này mỗi event, đừng sửa tay)");
  form.setConfirmationMessage("(placeholder — automation ghi đè mỗi event)");
  form.setLimitOneResponsePerUser(false); // bắt buộc: không đòi đăng nhập Google

  // Thu thập email kiểu Responder input (không bắt đăng nhập) — API mới;
  // account nào chưa có enum này thì fallback setCollectEmail + báo chỉnh tay
  try {
    form.setEmailCollectionType(FormApp.EmailCollectionType.RESPONDER_INPUT);
  } catch (e) {
    form.setCollectEmail(true);
    Logger.log("⚠ Không set được RESPONDER_INPUT bằng code — vào Settings form chỉnh 'Collect email addresses' = Responder input.");
  }

  form.addTextItem().setTitle("Họ và tên").setRequired(true);
  form.addTextItem().setTitle("Số điện thoại (có Zalo)").setRequired(true);
  form.addMultipleChoiceItem()
    .setTitle("Bạn là ai với Book!e?")
    .setChoiceValues(["Bookier (thành viên)", "Bookie's Friend — từng tham gia", "Lần đầu tham gia"])
    .setRequired(true);
  form.addMultipleChoiceItem()
    .setTitle("Bạn đã đọc cuốn sách của buổi này chưa?")
    .setHelpText("Với Book!e Talk (theo chủ đề): tính là cuốn sách bạn định mang theo.")
    .setChoiceValues(["Đã đọc", "Đang đọc", "Chưa đọc"])
    .setRequired(false);
  form.addMultipleChoiceItem()
    .setTitle("Bạn biết sự kiện qua đâu?")
    .setChoiceValues(["Fanpage", "Email", "Bạn bè giới thiệu", "Khác"])
    .setRequired(false);
  form.addParagraphTextItem()
    .setTitle("Câu hỏi / điều bạn muốn thảo luận")
    .setRequired(false);

  try {
    DriveApp.getFileById(form.getId()).moveTo(DriveApp.getFolderById(TEMPLATES_FOLDER_ID));
    Logger.log("✔ Form gốc đã tạo trong Templates/.");
  } catch (errMove) {
    // cần quyền Content manager+ trên Shared Drive — thiếu thì kéo tay từ My Drive vào
    Logger.log("⚠ Không chuyển được vào Templates/ (" + errMove + ") — form đang ở My Drive, kéo tay vào Bookie 2026/Templates/ giùm.");
  }
  Logger.log("TEMPLATE_ID = " + form.getId());
  Logger.log("Việc còn lại (UI): 1) chỉnh theme + ảnh header brand; 2) submit thử 1 response rồi xoá; 3) điền TEMPLATE_ID vào Script Properties.");
}

/**
 * Tạo calendar "Bookie Events" (giờ VN). Xem Log lấy CALENDAR_ID điền Script Properties.
 * Muốn embed lên website: mở Google Calendar Settings ▸ calendar này ▸
 * "Make available to public" — CalendarApp không bật public bằng code được.
 */
function setupEventsCalendar() {
  var cal = CalendarApp.createCalendar("Bookie Events", { timeZone: "Asia/Ho_Chi_Minh" });
  Logger.log("✔ Calendar đã tạo.");
  Logger.log("CALENDAR_ID = " + cal.getId());
  Logger.log("Việc còn lại (UI): Calendar Settings ▸ Make available to public (để embed website đọc được).");
}
