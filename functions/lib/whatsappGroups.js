const {
  WHATSAPP_GROUP_PUTRA_PAGI_ID,
  WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL,
  WHATSAPP_GROUP_PUTRA_SORE_ID,
  WHATSAPP_GROUP_PUTRA_SORE_INVITE_URL,
  WHATSAPP_GROUP_PUTRA_MALAM_ID,
  WHATSAPP_GROUP_PUTRA_MALAM_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_PAGI_ID,
  WHATSAPP_GROUP_PUTRI_PAGI_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_SORE_ID,
  WHATSAPP_GROUP_PUTRI_SORE_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_MALAM_ID,
  WHATSAPP_GROUP_PUTRI_MALAM_INVITE_URL,
} = require("./config");

// Identitas grup merupakan sumber tunggal untuk dua kebutuhan:
// 1. memilih link grup pada welcome message berdasarkan gender + sesi;
// 2. mengirim reminder bulanan ke seluruh grup yang sudah dikonfigurasi.
const WHATSAPP_GROUP_IDENTITIES = Object.freeze([
  Object.freeze({
    key: "putra_pagi",
    gender: "L",
    session: "pagi",
    label: "Putra Pagi",
    groupIdParam: WHATSAPP_GROUP_PUTRA_PAGI_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL,
  }),
  Object.freeze({
    key: "putra_sore",
    gender: "L",
    session: "sore",
    label: "Putra Sore",
    groupIdParam: WHATSAPP_GROUP_PUTRA_SORE_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRA_SORE_INVITE_URL,
  }),
  Object.freeze({
    key: "putra_malam",
    gender: "L",
    session: "malam",
    label: "Putra Malam",
    groupIdParam: WHATSAPP_GROUP_PUTRA_MALAM_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRA_MALAM_INVITE_URL,
  }),
  Object.freeze({
    key: "putri_pagi",
    gender: "P",
    session: "pagi",
    label: "Putri Pagi",
    groupIdParam: WHATSAPP_GROUP_PUTRI_PAGI_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRI_PAGI_INVITE_URL,
  }),
  Object.freeze({
    key: "putri_sore",
    gender: "P",
    session: "sore",
    label: "Putri Sore",
    groupIdParam: WHATSAPP_GROUP_PUTRI_SORE_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRI_SORE_INVITE_URL,
  }),
  Object.freeze({
    key: "putri_malam",
    gender: "P",
    session: "malam",
    label: "Putri Malam",
    groupIdParam: WHATSAPP_GROUP_PUTRI_MALAM_ID,
    inviteUrlParam: WHATSAPP_GROUP_PUTRI_MALAM_INVITE_URL,
  }),
]);

function normalizeGender(value) {
  const normalized = String(value || "").trim().toLowerCase();
  if (["l", "putra", "laki-laki", "laki laki"].includes(normalized)) {
    return "L";
  }
  if (["p", "putri", "perempuan"].includes(normalized)) return "P";
  return null;
}

function normalizeSession(value) {
  const normalized = String(value || "").trim().toLowerCase();
  return ["pagi", "sore", "malam"].includes(normalized) ? normalized : null;
}

function normalizeHttpsUrl(value) {
  const normalized = String(value || "").trim();
  if (!normalized) return null;
  try {
    const parsed = new URL(normalized);
    return parsed.protocol === "https:" ? normalized : null;
  } catch (_) {
    return null;
  }
}

function findWhatsAppGroupIdentity(gender, session) {
  const normalizedGender = normalizeGender(gender);
  const normalizedSession = normalizeSession(session);
  if (!normalizedGender || !normalizedSession) return null;
  return (
    WHATSAPP_GROUP_IDENTITIES.find(
      (item) =>
        item.gender === normalizedGender && item.session === normalizedSession,
    ) || null
  );
}

function resolveWhatsAppGroup(gender, session, overrides = {}) {
  const identity = findWhatsAppGroupIdentity(gender, session);
  if (!identity) return null;
  const override = overrides[identity.key];
  const groupId = String(
    override?.groupId === undefined
      ? identity.groupIdParam.value()
      : override.groupId,
  ).trim();
  const rawInviteUrl =
    override?.inviteUrl === undefined
      ? identity.inviteUrlParam.value()
      : override.inviteUrl;

  return {
    key: identity.key,
    gender: identity.gender,
    session: identity.session,
    label: identity.label,
    groupId: groupId || null,
    inviteUrl: normalizeHttpsUrl(rawInviteUrl),
  };
}

function configuredWhatsAppGroups(overrides = {}) {
  const groups = [];
  const seenGroupIds = new Set();
  for (const identity of WHATSAPP_GROUP_IDENTITIES) {
    const group = resolveWhatsAppGroup(
      identity.gender,
      identity.session,
      overrides,
    );
    if (!group?.groupId || seenGroupIds.has(group.groupId)) continue;
    seenGroupIds.add(group.groupId);
    groups.push(group);
  }
  return groups;
}

module.exports = {
  WHATSAPP_GROUP_IDENTITIES,
  normalizeGender,
  normalizeSession,
  normalizeHttpsUrl,
  findWhatsAppGroupIdentity,
  resolveWhatsAppGroup,
  configuredWhatsAppGroups,
};
