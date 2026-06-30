const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// API key Groq (gratis: https://console.groq.com/keys). Disimpan di Secret
// Manager: `firebase functions:secrets:set GROQ_API_KEY`.
const GROQ_API_KEY = defineSecret("GROQ_API_KEY");

const OPTIONS = {
  region: "asia-southeast2",
  memory: "512MiB",
  timeoutSeconds: 120,
  secrets: [GROQ_API_KEY],
};

const GROQ_URL = "https://api.groq.com/openai/v1/audio/transcriptions";

// Model Whisper di Groq. `whisper-large-v3` paling akurat (dipakai default);
// `whisper-large-v3-turbo` lebih cepat & murah tapi sedikit kurang akurat.
const DEFAULT_MODEL = "whisper-large-v3";

const EXT_BY_MIME = {
  "audio/mp4": "m4a",
  "audio/m4a": "m4a",
  "audio/aac": "m4a",
  "audio/mpeg": "mp3",
  "audio/wav": "wav",
  "audio/x-wav": "wav",
  "audio/webm": "webm",
  "audio/ogg": "ogg",
  "audio/flac": "flac",
};

// onCall: dipanggil dari app via package cloud_functions (httpsCallable).
// data: { audioBase64: string, mimeType?: string, model?: string }
// return: { text: string, model: string }
exports.transcribeRecitation = onCall(OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }

  const audioBase64 = request.data && request.data.audioBase64;
  if (!audioBase64 || typeof audioBase64 !== "string") {
    throw new HttpsError("invalid-argument", "audioBase64 wajib diisi.");
  }

  const mimeType = (request.data.mimeType || "audio/mp4").toLowerCase();
  const ext = EXT_BY_MIME[mimeType] || "m4a";
  const model = request.data.model || DEFAULT_MODEL;

  const buffer = Buffer.from(audioBase64, "base64");
  // Batas wajar Phase 0: ~10 MB audio mentah (callable max payload 10MB base64).
  if (buffer.length === 0) {
    throw new HttpsError("invalid-argument", "Audio kosong.");
  }
  if (buffer.length > 24 * 1024 * 1024) {
    throw new HttpsError("invalid-argument", "Audio terlalu besar (maks 24MB).");
  }

  const form = new FormData();
  form.append("file", new Blob([buffer], { type: mimeType }), `audio.${ext}`);
  form.append("model", model);
  form.append("language", "ar"); // paksa Arab (hindari salah deteksi bahasa)
  form.append("response_format", "json");
  form.append("temperature", "0");

  let resp;
  try {
    resp = await fetch(GROQ_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${GROQ_API_KEY.value()}` },
      body: form,
    });
  } catch (err) {
    console.error("transcribeRecitation fetch error:", err);
    throw new HttpsError("unavailable", "Gagal menghubungi layanan transkripsi.");
  }

  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    console.error("Groq error", resp.status, detail);
    if (resp.status === 429) {
      throw new HttpsError("resource-exhausted", "Kuota transkripsi habis, coba lagi nanti.");
    }
    throw new HttpsError("internal", `Transkripsi gagal (${resp.status}).`);
  }

  const json = await resp.json();
  return { text: (json.text || "").trim(), model };
});
