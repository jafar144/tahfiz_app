const {
  WABLAS_BASE_URL,
  WABLAS_ENABLED,
} = require("./config");

const MAX_MESSAGES_PER_REQUEST = 100;
const REQUEST_TIMEOUT_MS = 30_000;

function isWablasEnabled(value = WABLAS_ENABLED.value()) {
  return ["1", "true", "yes", "on"].includes(
    String(value || "").trim().toLowerCase()
  );
}

function normalizeBaseUrl(value) {
  const normalized = String(value || "").trim().replace(/\/+$/, "");
  let parsed;
  try {
    parsed = new URL(normalized);
  } catch (_) {
    throw new Error("WABLAS_BASE_URL tidak valid.");
  }
  if (parsed.protocol !== "https:") {
    throw new Error("WABLAS_BASE_URL wajib menggunakan HTTPS.");
  }
  return normalized;
}

function normalizeWhatsAppPhone(value) {
  let phone = String(value || "").replace(/\D/g, "");
  if (!phone) return null;
  if (phone.startsWith("0")) phone = `62${phone.slice(1)}`;
  else if (phone.startsWith("8")) phone = `62${phone}`;
  if (!phone.startsWith("62") || phone.length < 10 || phone.length > 15) {
    return null;
  }
  return phone;
}

function chunks(items, size) {
  const result = [];
  for (let i = 0; i < items.length; i += size) {
    result.push(items.slice(i, i + size));
  }
  return result;
}

function buildPayload(messages) {
  return {
    data: messages.map((item) => {
      const isGroup = String(item.isGroup || "false").toLowerCase() === "true";
      const phone = isGroup
        ? String(item.phone || "").trim()
        : normalizeWhatsAppPhone(item.phone);
      if (!phone) throw new Error("Nomor tujuan WhatsApp tidak valid.");
      if (!String(item.message || "").trim()) {
        throw new Error("Isi pesan WhatsApp tidak boleh kosong.");
      }
      return {
        phone,
        message: String(item.message).trim(),
        isGroup: isGroup ? "true" : "false",
        ...(item.refId ? { ref_id: String(item.refId) } : {}),
      };
    }),
  };
}

async function parseResponse(response) {
  const raw = await response.text();
  let body;
  try {
    body = raw ? JSON.parse(raw) : {};
  } catch (_) {
    body = { message: raw };
  }
  if (!response.ok || body.status === false) {
    const detail = body.message || `HTTP ${response.status}`;
    const errorId = body.error_id ? ` (error_id: ${body.error_id})` : "";
    throw new Error(`Wablas menolak request: ${detail}${errorId}`);
  }
  return body;
}

async function sendTextMessages(messages, options = {}) {
  if (!Array.isArray(messages) || messages.length === 0) {
    return { requestCount: 0, messageCount: 0, responses: [] };
  }

  const baseUrl = normalizeBaseUrl(
    options.baseUrl === undefined ? WABLAS_BASE_URL.value() : options.baseUrl
  );
  const secrets =
    options.token === undefined || options.secretKey === undefined
      ? require("./wablasSecrets")
      : null;
  const token = String(
    options.token === undefined
      ? secrets.WABLAS_TOKEN.value()
      : options.token
  ).trim();
  const secretKey = String(
    options.secretKey === undefined
      ? secrets.WABLAS_SECRET_KEY.value()
      : options.secretKey
  ).trim();
  if (!token || !secretKey) throw new Error("Credential Wablas belum tersedia.");

  const fetchImpl = options.fetchImpl || globalThis.fetch;
  if (typeof fetchImpl !== "function") throw new Error("Fetch API tidak tersedia.");

  const responses = [];
  for (const batch of chunks(messages, MAX_MESSAGES_PER_REQUEST)) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetchImpl(`${baseUrl}/api/v2/send-message`, {
        method: "POST",
        headers: {
          Authorization: `${token}.${secretKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(buildPayload(batch)),
        signal: controller.signal,
      });
      responses.push(await parseResponse(response));
    } finally {
      clearTimeout(timeout);
    }
  }

  return {
    requestCount: responses.length,
    messageCount: messages.length,
    responses,
  };
}

module.exports = {
  MAX_MESSAGES_PER_REQUEST,
  isWablasEnabled,
  normalizeBaseUrl,
  normalizeWhatsAppPhone,
  buildPayload,
  sendTextMessages,
};
