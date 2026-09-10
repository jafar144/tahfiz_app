const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const {
  passwordFromBirthDate,
  toJakartaDateString,
} = require("../lib/utils");

function requiredSantriId(value) {
  const id = String(value ?? "").trim();
  if (!id || id.length > 128) {
    throw new HttpsError("invalid-argument", "ID santri tidak valid.");
  }
  return id;
}

function birthDateInput(value, now = new Date()) {
  const text = String(value ?? "").trim();
  const match = text.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!match) {
    throw new HttpsError(
      "invalid-argument",
      "Tanggal lahir harus berformat YYYY-MM-DD.",
    );
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const calendarCheck = new Date(Date.UTC(year, month - 1, day));
  const validCalendarDate =
    calendarCheck.getUTCFullYear() === year &&
    calendarCheck.getUTCMonth() === month - 1 &&
    calendarCheck.getUTCDate() === day;
  const today = toJakartaDateString(now);
  if (
    !validCalendarDate ||
    text < "1900-01-01" ||
    !today ||
    text > today
  ) {
    throw new HttpsError("invalid-argument", "Tanggal lahir tidak valid.");
  }

  return {
    text,
    date: new Date(`${text}T00:00:00+07:00`),
    password: passwordFromBirthDate(text),
  };
}

async function runResetSantriPasswordFromBirthDate(request, overrides = {}) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }

  const firestore = overrides.firestore || db;
  const auth = overrides.auth || admin.auth();
  const assertAdminFn = overrides.assertAdminFn || assertAdmin;
  const timestampFromDate =
    overrides.timestampFromDate || admin.firestore.Timestamp.fromDate;
  const serverTimestamp =
    overrides.serverTimestamp || admin.firestore.FieldValue.serverTimestamp;
  const deleteField =
    overrides.deleteField || admin.firestore.FieldValue.delete;

  await assertAdminFn(request.auth.uid);
  const santriId = requiredSantriId(request.data?.santriId);
  const birthDate = birthDateInput(request.data?.birthDate, overrides.now);
  const userSnapshot = await firestore.collection("users").doc(santriId).get();
  const profileRef = firestore.collection("santri_profiles").doc(santriId);
  const profileSnapshot = await profileRef.get();

  if (!userSnapshot.exists || userSnapshot.data()?.role !== "santri") {
    throw new HttpsError("failed-precondition", "Akun santri tidak valid.");
  }
  if (!profileSnapshot.exists) {
    throw new HttpsError("not-found", "Profil santri tidak ditemukan.");
  }

  // Marker pending membuat alur lintas Auth + Firestore dapat dipulihkan bila
  // koneksi terputus di tengah proses. Marker tidak berisi password.
  await profileRef.update({
    tanggal_lahir: timestampFromDate(birthDate.date),
    password_reset_pending_birth_date: birthDate.text,
    updated_at: serverTimestamp(),
  });

  try {
    await auth.updateUser(santriId, { password: birthDate.password });
    await auth.revokeRefreshTokens(santriId);
    await profileRef.update({
      password_birth_date_key: birthDate.text,
      password_reset_pending_birth_date: deleteField(),
      password_reset_at: serverTimestamp(),
      updated_at: serverTimestamp(),
    });
  } catch (error) {
    console.error("Reset password tanggal lahir belum selesai", {
      santriId,
      code: error?.code || "unknown",
    });
    throw new HttpsError(
      "internal",
      "Tanggal lahir tersimpan, tetapi reset password belum selesai. Silakan coba lagi.",
    );
  }

  // Password tidak pernah dikembalikan ke aplikasi atau dicatat di log.
  return { reset: true };
}

const resetSantriPasswordFromBirthDate = onCall(
  CALLABLE_OPTIONS,
  runResetSantriPasswordFromBirthDate,
);

module.exports = {
  resetSantriPasswordFromBirthDate,
  _private: {
    birthDateInput,
    requiredSantriId,
    runResetSantriPasswordFromBirthDate,
  },
};
