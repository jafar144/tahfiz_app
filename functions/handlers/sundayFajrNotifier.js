const { logger } = require("firebase-functions");
const { db } = require("../lib/firebase");
const { monthNameId } = require("../lib/jakartaTime");
const { sendToUid } = require("../lib/messaging");
const {
  isWablasEnabled,
  normalizeWhatsAppPhone,
  sendTextMessages,
} = require("../lib/wablas");
const { resolveWhatsAppGroup } = require("../lib/whatsappGroups");
const {
  buildSundayFajrAlphaAnnouncement,
} = require("../lib/whatsappMessages");

const SUNDAY_FAJR_COLLECTION = "sunday_fajr_attendance";
const SUNDAY_FAJR_PARTICIPANTS_COLLECTION = "participants";
const SUNDAY_FAJR_TARGET_GROUPS = Object.freeze([
  Object.freeze({ gender: "L", session: "Sore", key: "putra_sore" }),
  Object.freeze({ gender: "L", session: "Malam", key: "putra_malam" }),
]);

function calendarDate(parts, offsetDays = 0) {
  const date = new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
  if (
    !Number.isInteger(parts.year) ||
    !Number.isInteger(parts.month) ||
    !Number.isInteger(parts.day) ||
    date.getUTCFullYear() !== parts.year ||
    date.getUTCMonth() + 1 !== parts.month ||
    date.getUTCDate() !== parts.day
  ) {
    throw new TypeError("Tanggal scheduler Minggu Subuh tidak valid.");
  }
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date;
}

function isMonday(parts) {
  return calendarDate(parts).getUTCDay() === 1;
}

function dateParts(date) {
  return {
    year: date.getUTCFullYear(),
    month: date.getUTCMonth() + 1,
    day: date.getUTCDate(),
  };
}

function dateKey(parts) {
  return `${parts.year}-${String(parts.month).padStart(2, "0")}-${String(
    parts.day,
  ).padStart(2, "0")}`;
}

function previousSunday(parts) {
  if (!isMonday(parts)) {
    throw new TypeError("Notifikasi Minggu Subuh hanya diproses pada hari Senin.");
  }
  return dateParts(calendarDate(parts, -1));
}

async function fetchSundayFajrAlphas(weekKey, firestore = db) {
  const attendanceRef = firestore
    .collection(SUNDAY_FAJR_COLLECTION)
    .doc(weekKey);
  const attendance = await attendanceRef.get();
  if (!attendance.exists) {
    logger.info(`[sundayFajrAlpha] absensi ${weekKey} belum tersimpan.`);
    return [];
  }

  const totalAlpha = Number(attendance.data()?.total_alpha || 0);
  if (totalAlpha <= 0) {
    logger.info(`[sundayFajrAlpha] tidak ada alpha pada ${weekKey}.`);
    return [];
  }

  const snapshot = await attendanceRef
    .collection(SUNDAY_FAJR_PARTICIPANTS_COLLECTION)
    .where("status", "==", "alpha")
    .get();
  const participants = snapshot.docs
    .map((document) => {
      const data = document.data() || {};
      return {
        uid: String(data.santri_id || document.id || "").trim(),
        name: String(data.santri_name || "").trim(),
      };
    })
    .filter((participant) => participant.uid && participant.name);

  participants.sort((first, second) =>
    first.name.localeCompare(second.name, "id-ID", { sensitivity: "base" }),
  );
  return participants;
}

async function fetchSantriPhones(participants, firestore = db) {
  const snapshots = await Promise.all(
    participants.map((participant) =>
      firestore.collection("users").doc(participant.uid).get(),
    ),
  );
  return new Map(
    participants.map((participant, index) => [
      participant.uid,
      snapshots[index].exists ? snapshots[index].data()?.phone || "" : "",
    ]),
  );
}

function buildSundayFajrPushNotification(participant, eventParts, weekKey) {
  return {
    title: "Pengumuman Absensi Minggu Subuh",
    body:
      `Anda tercatat tidak mengikuti Sholat Subuh berjamaah tanpa uzur pada ` +
      `Ahad, ${eventParts.day} ${monthNameId(eventParts.month)} ${eventParts.year}. ` +
      "Anda tidak diperkenankan mengikuti kegiatan belajar selama 3 pertemuan pekan ini.",
    data: {
      type: "sunday_fajr_alpha",
      week_key: weekKey,
      santri_id: participant.uid,
    },
  };
}

function configuredTargetGroups(overrides = {}) {
  const groups = [];
  const seenIds = new Set();
  for (const target of SUNDAY_FAJR_TARGET_GROUPS) {
    const group = resolveWhatsAppGroup(
      target.gender,
      target.session,
      overrides,
    );
    if (!group?.groupId || seenIds.has(group.groupId)) continue;
    seenIds.add(group.groupId);
    groups.push(group);
  }
  return groups;
}

function prepareSundayFajrWhatsAppMessages({
  weekKey,
  eventParts,
  participants,
  phones,
  groups,
}) {
  const announcement = buildSundayFajrAlphaAnnouncement(
    eventParts,
    participants,
  );
  const messages = [];
  const seenPersonalPhones = new Set();
  let invalidPhoneCount = 0;

  for (const participant of participants) {
    const rawPhone =
      phones instanceof Map ? phones.get(participant.uid) : phones?.[participant.uid];
    const phone = normalizeWhatsAppPhone(rawPhone);
    if (!phone) {
      invalidPhoneCount += 1;
      continue;
    }
    if (seenPersonalPhones.has(phone)) continue;
    seenPersonalPhones.add(phone);
    messages.push({
      phone,
      message: announcement,
      isGroup: "false",
      refId: `sunday-fajr-alpha-${weekKey}-${participant.uid}`,
    });
  }

  for (const group of groups) {
    const groupId = String(group?.groupId || "").trim();
    if (!groupId) continue;
    messages.push({
      phone: groupId,
      message: announcement,
      isGroup: "true",
      refId: `sunday-fajr-alpha-${weekKey}-${group.key}`,
    });
  }

  return {
    announcement,
    messages,
    personalCount: seenPersonalPhones.size,
    groupCount: messages.length - seenPersonalPhones.size,
    invalidPhoneCount,
  };
}

async function runSundayFajrAppNotifications(
  weekKey,
  eventParts,
  participants,
  options = {},
) {
  const push = options.sendPush || sendToUid;
  let notified = 0;
  let pushFailed = 0;
  let successCount = 0;
  let failureCount = 0;

  for (const participant of participants) {
    try {
      const result = await push(
        participant.uid,
        buildSundayFajrPushNotification(participant, eventParts, weekKey),
      );
      notified += 1;
      successCount += Number(result?.successCount || 0);
      failureCount += Number(result?.failureCount || 0);
    } catch (error) {
      pushFailed += 1;
      logger.error(
        `[sundayFajrAlpha] notifikasi HP ke ${participant.uid} gagal: ${error.message}`,
      );
    }
  }

  return { notified, pushFailed, successCount, failureCount };
}

async function runSundayFajrWhatsApp(
  weekKey,
  eventParts,
  participants,
  options = {},
) {
  const enabled =
    options.enabled === undefined ? isWablasEnabled() : options.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const groups =
    options.groups === undefined
      ? configuredTargetGroups(options.groupOverrides)
      : options.groups;
  const resolvePhones = options.fetchPhones || fetchSantriPhones;
  let phones;
  let phoneLookupError = null;
  try {
    phones = await resolvePhones(participants);
  } catch (error) {
    phoneLookupError = error;
    phones = new Map();
    logger.error(
      `[sundayFajrAlpha] nomor WA santri gagal dibaca: ${error.message}`,
    );
  }
  const prepared = prepareSundayFajrWhatsAppMessages({
    weekKey,
    eventParts,
    participants,
    phones,
    groups,
  });

  if (!prepared.messages.length) {
    return {
      skipped: true,
      reason: "no_valid_recipients",
      invalidPhone: prepared.invalidPhoneCount,
      ...(phoneLookupError
        ? { phoneLookupError: phoneLookupError.message }
        : {}),
    };
  }

  try {
    const send = options.send || sendTextMessages;
    const provider = await send(prepared.messages);
    return {
      sent: prepared.messages.length,
      failed: 0,
      personal: prepared.personalCount,
      groups: prepared.groupCount,
      invalidPhone: prepared.invalidPhoneCount,
      ...(phoneLookupError
        ? { phoneLookupError: phoneLookupError.message }
        : {}),
      provider,
    };
  } catch (error) {
    logger.error(
      `[sundayFajrAlpha] pengiriman WhatsApp gagal: ${error.message}`,
    );
    return {
      sent: 0,
      failed: prepared.messages.length,
      personal: prepared.personalCount,
      groups: prepared.groupCount,
      invalidPhone: prepared.invalidPhoneCount,
      ...(phoneLookupError
        ? { phoneLookupError: phoneLookupError.message }
        : {}),
      error: error.message,
    };
  }
}

async function runSundayFajrAlphaNotifications(parts, options = {}) {
  if (!isMonday(parts)) {
    return { skipped: true, reason: "not_monday" };
  }

  const eventParts = previousSunday(parts);
  const weekKey = dateKey(eventParts);
  const fetchAlphas = options.fetchAlphas || fetchSundayFajrAlphas;
  const participants = await fetchAlphas(weekKey);
  if (!participants.length) {
    return { skipped: true, reason: "no_alpha", weekKey };
  }

  const [app, whatsapp] = await Promise.all([
    runSundayFajrAppNotifications(
      weekKey,
      eventParts,
      participants,
      options.app,
    ),
    runSundayFajrWhatsApp(
      weekKey,
      eventParts,
      participants,
      options.whatsapp,
    ),
  ]);

  logger.info(
    `[sundayFajrAlpha] ${participants.length} santri alpha pada ${weekKey}; ` +
      `notifikasi HP diproses ${app.notified}, WhatsApp terkirim ${
        whatsapp.sent || 0
      }.`,
  );
  return {
    skipped: false,
    weekKey,
    alphaCount: participants.length,
    app,
    whatsapp,
  };
}

module.exports = {
  SUNDAY_FAJR_COLLECTION,
  SUNDAY_FAJR_PARTICIPANTS_COLLECTION,
  SUNDAY_FAJR_TARGET_GROUPS,
  isMonday,
  dateKey,
  previousSunday,
  fetchSundayFajrAlphas,
  fetchSantriPhones,
  buildSundayFajrPushNotification,
  configuredTargetGroups,
  prepareSundayFajrWhatsAppMessages,
  runSundayFajrAppNotifications,
  runSundayFajrWhatsApp,
  runSundayFajrAlphaNotifications,
};
