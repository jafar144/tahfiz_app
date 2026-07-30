const crypto = require("node:crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const {
  AUTH_EMAIL_DOMAIN,
  CALLABLE_OPTIONS,
  STAFF_INITIAL_PASSWORD,
} = require("../lib/config");
const { normNis, passwordFromBirthDate } = require("../lib/utils");
const {
  runSantriWelcomeWhatsApp,
} = require("./whatsappNotifier");

const TEMPORARY_PASSWORD_ALPHABET =
  "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$";

const wablasEnabledAtDeploy = ["1", "true", "yes", "on"].includes(
  String(process.env.WABLAS_ENABLED || "").trim().toLowerCase(),
);
const wablasSecrets = wablasEnabledAtDeploy
  ? Object.values(require("../lib/wablasSecrets"))
  : [];
const PROVISION_OPTIONS = {
  ...CALLABLE_OPTIONS,
  secrets: wablasSecrets,
};

function requiredText(value, field, maxLength = 160) {
  const text = String(value ?? "").trim();
  if (!text) {
    throw new HttpsError("invalid-argument", `${field} wajib diisi.`);
  }
  if (text.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `${field} maksimal ${maxLength} karakter.`,
    );
  }
  return text;
}

function optionalText(value, maxLength = 240) {
  const text = String(value ?? "").trim();
  if (text.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `Nilai maksimal ${maxLength} karakter.`,
    );
  }
  return text;
}

function dateOnly(value, field, { required = true } = {}) {
  const text = String(value ?? "").trim();
  if (!text && !required) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    throw new HttpsError(
      "invalid-argument",
      `${field} harus berformat YYYY-MM-DD.`,
    );
  }
  const date = new Date(`${text}T00:00:00+07:00`);
  if (Number.isNaN(date.getTime())) {
    throw new HttpsError("invalid-argument", `${field} tidak valid.`);
  }
  return { text, timestamp: admin.firestore.Timestamp.fromDate(date) };
}

function randomTemporaryPassword(length = 16) {
  const bytes = crypto.randomBytes(length);
  let password = "";
  for (let index = 0; index < length; index += 1) {
    password +=
      TEMPORARY_PASSWORD_ALPHABET[
        bytes[index] % TEMPORARY_PASSWORD_ALPHABET.length
      ];
  }
  return password;
}

function staffInitialPassword(configuredValue) {
  const password = String(configuredValue ?? "").trim();
  if (!password) return randomTemporaryPassword();
  if (
    password.length < 12 ||
    password.length > 128 ||
    !/[a-z]/.test(password) ||
    !/[A-Z]/.test(password) ||
    !/[0-9]/.test(password)
  ) {
    throw new HttpsError(
      "failed-precondition",
      "STAFF_INITIAL_PASSWORD harus 12-128 karakter dan memuat huruf besar, huruf kecil, serta angka.",
    );
  }
  return password;
}

async function rollbackAuthUser(uid) {
  try {
    await admin.auth().deleteUser(uid);
  } catch (error) {
    console.error("Gagal rollback user Auth:", uid, error);
  }
}

const provisionInstitutionUser = onCall(PROVISION_OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  await assertAdmin(request.auth.uid);

  const data = request.data || {};
  const role = requiredText(data.role, "role", 20);
  if (role !== "santri" && role !== "asatidz") {
    throw new HttpsError(
      "invalid-argument",
      "role harus bernilai santri atau asatidz.",
    );
  }

  const nis = normNis(requiredText(data.nis, "nis", 40));
  if (!nis || !/^[A-Za-z0-9._-]+$/.test(nis)) {
    throw new HttpsError(
      "invalid-argument",
      "NIS hanya boleh berisi huruf, angka, titik, garis bawah, atau tanda minus.",
    );
  }

  const name = requiredText(data.name, "name");
  const phone = optionalText(data.phone, 40);
  const jenisKelamin = requiredText(data.jenisKelamin, "jenisKelamin", 1);
  if (jenisKelamin !== "L" && jenisKelamin !== "P") {
    throw new HttpsError(
      "invalid-argument",
      "jenisKelamin harus bernilai L atau P.",
    );
  }

  const photoUrl = optionalText(data.photoUrl, 1000);
  const email = `${nis}@${AUTH_EMAIL_DOMAIN.value()}`;
  const now = admin.firestore.FieldValue.serverTimestamp();
  let temporaryPassword;
  let profileData;

  if (role === "santri") {
    const birthDate = dateOnly(data.birthDate, "birthDate");
    const entryDate = dateOnly(data.entryDate, "entryDate");
    const freeUntil = dateOnly(data.freeUntil, "freeUntil", { required: false });
    temporaryPassword = passwordFromBirthDate(birthDate.text);
    const kelasFiqih = optionalText(data.kelasFiqih, 80);
    profileData = {
      is_active: data.isActive !== false,
      free_until: data.isFree === true ? freeUntil?.timestamp || null : null,
      halaqah_id: null,
      jenis_kelamin: jenisKelamin,
      kelas: requiredText(data.kelas, "kelas", 80),
      nama_wali: optionalText(data.waliName),
      nomor_wali: optionalText(data.waliPhone, 40),
      name,
      nis,
      tanggal_lahir: birthDate.timestamp,
      tanggal_masuk: entryDate.timestamp,
      tempat_lahir: optionalText(data.birthPlace),
      tipe_kelas: requiredText(data.tipeKelas, "tipeKelas", 80),
      uid: null,
      created_at: now,
      ...(kelasFiqih ? { kelas_fiqih: kelasFiqih } : {}),
      ...(photoUrl ? { photo_url: photoUrl } : {}),
    };
  } else {
    const configuredStaffPassword = STAFF_INITIAL_PASSWORD.value();
    temporaryPassword = staffInitialPassword(configuredStaffPassword);
    profileData = {
      is_active: data.isActive !== false,
      jenis_kelamin: jenisKelamin,
      name,
      nis,
      uid: null,
      created_at: now,
      ...(photoUrl ? { photo_url: photoUrl } : {}),
    };
  }

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email,
      password: temporaryPassword,
      displayName: name,
      disabled: data.isActive === false,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        `NIS ${nis} sudah mempunyai akun.`,
      );
    }
    console.error("createUser gagal:", error);
    throw new HttpsError("internal", "Gagal membuat akun pengguna.");
  }

  const uid = userRecord.uid;
  profileData.uid = uid;
  const userData = {
    name,
    email,
    nis,
    phone,
    role,
    is_admin: false,
    uid,
    created_at: now,
    ...(photoUrl ? { photo_url: photoUrl } : {}),
  };

  try {
    const batch = db.batch();
    batch.create(db.collection("users").doc(uid), userData);
    batch.create(
      db
        .collection(
          role === "santri" ? "santri_profiles" : "asatidz_profiles",
        )
        .doc(uid),
      profileData,
    );
    await batch.commit();
  } catch (error) {
    await rollbackAuthUser(uid);
    console.error("Provisioning Firestore gagal:", error);
    throw new HttpsError(
      "internal",
      "Akun dibatalkan karena profil gagal disimpan.",
    );
  }

  let whatsapp = { skipped: true, reason: "not_a_santri" };
  if (role === "santri") {
    try {
      whatsapp = await runSantriWelcomeWhatsApp(
        {
          uid,
          name,
          nis,
          phone,
          nomorWali: profileData.nomor_wali,
          kelas: profileData.kelas,
          tipeKelas: profileData.tipe_kelas,
          jenisKelamin: profileData.jenis_kelamin,
        },
        temporaryPassword,
      );
    } catch (error) {
      // Akun dan profil sudah berhasil dibuat. Gangguan provider WhatsApp tidak
      // boleh membuat klien mengulang provisioning dan menghasilkan duplikasi.
      console.error("Welcome WhatsApp santri gagal:", error);
      whatsapp = { sent: 0, failed: 1, reason: "unexpected_error" };
    }
  }

  return {
    uid,
    role,
    nis,
    email,
    temporaryPassword,
    whatsapp,
  };
});

module.exports = {
  provisionInstitutionUser,
  _private: {
    requiredText,
    dateOnly,
    randomTemporaryPassword,
    staffInitialPassword,
  },
};
