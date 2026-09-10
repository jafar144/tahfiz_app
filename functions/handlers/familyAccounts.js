"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { CALLABLE_OPTIONS } = require("../lib/config");

function normalizedId(value) {
  return typeof value === "string" ? value.trim() : "";
}

function uniqueMemberIds(family) {
  const ids = Array.isArray(family?.santriIds) ? family.santriIds : [];
  return [...new Set(ids.map(normalizedId).filter(Boolean))];
}

function accountFromProfile(profile) {
  if (!profile?.exists) return null;
  const data = profile.data || {};
  if (data.is_active === false) return null;

  return {
    id: profile.id,
    name: normalizedId(data.name),
    nis: normalizedId(data.nis),
    kelas: normalizedId(data.kelas),
    jenisKelamin: normalizedId(data.jenis_kelamin).toUpperCase(),
    photoUrl: normalizedId(data.photo_url),
  };
}

function createFamilyAccountService({
  getUser,
  findFamilies,
  getProfiles,
  createCustomToken,
}) {
  async function assertSantri(uid) {
    const user = await getUser(uid);
    if (!user?.exists || user.data?.role !== "santri") {
      throw new HttpsError(
        "permission-denied",
        "Fitur ganti akun hanya tersedia untuk akun santri.",
      );
    }
  }

  async function familyFor(uid) {
    const families = await findFamilies(uid);
    if (families.length > 1) {
      throw new HttpsError(
        "failed-precondition",
        "Data keluarga terduplikasi. Hubungi admin untuk memperbaikinya.",
      );
    }
    return families[0] || null;
  }

  async function getAccounts(uid) {
    await assertSantri(uid);
    const family = await familyFor(uid);
    if (family == null) return [];

    const ids = uniqueMemberIds(family).filter((id) => id !== uid);
    if (ids.length === 0) return [];

    const [profiles, users] = await Promise.all([
      getProfiles(ids),
      Promise.all(ids.map((id) => getUser(id))),
    ]);
    const byId = new Map(profiles.map((profile) => [profile.id, profile]));
    return ids
      .map((id, index) => {
        if (!users[index]?.exists || users[index].data?.role !== "santri") {
          return null;
        }
        return accountFromProfile(byId.get(id));
      })
      .filter((account) => account != null);
  }

  async function createSwitchToken(uid, rawTargetId) {
    await assertSantri(uid);
    const targetId = normalizedId(rawTargetId);
    if (!targetId || targetId === uid) {
      throw new HttpsError(
        "invalid-argument",
        "Akun tujuan tidak valid.",
      );
    }

    const family = await familyFor(uid);
    if (family == null || !uniqueMemberIds(family).includes(targetId)) {
      throw new HttpsError(
        "permission-denied",
        "Akun tujuan bukan anggota keluarga Anda.",
      );
    }

    const [targetUser, profiles] = await Promise.all([
      getUser(targetId),
      getProfiles([targetId]),
    ]);
    const targetAccount = accountFromProfile(profiles[0]);
    if (
      !targetUser?.exists ||
      targetUser.data?.role !== "santri" ||
      targetAccount == null
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Akun tujuan tidak aktif atau tidak dapat digunakan.",
      );
    }

    try {
      return await createCustomToken(targetId);
    } catch (_) {
      throw new HttpsError(
        "failed-precondition",
        "Akun tujuan tidak dapat membuat sesi login.",
      );
    }
  }

  return { getAccounts, createSwitchToken };
}

const service = createFamilyAccountService({
  getUser: async (uid) => {
    const snapshot = await db.collection("users").doc(uid).get();
    return {
      exists: snapshot.exists,
      data: snapshot.exists ? snapshot.data() || {} : {},
    };
  },
  findFamilies: async (uid) => {
    const snapshot = await db
      .collection("families")
      .where("santri_ids", "array-contains", uid)
      .limit(2)
      .get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      santriIds: doc.data()?.santri_ids,
    }));
  },
  getProfiles: async (ids) => {
    if (ids.length === 0) return [];
    const references = ids.map((id) =>
      db.collection("santri_profiles").doc(id),
    );
    const snapshots = await db.getAll(...references);
    return snapshots.map((snapshot) => ({
      id: snapshot.id,
      exists: snapshot.exists,
      data: snapshot.exists ? snapshot.data() || {} : {},
    }));
  },
  createCustomToken: async (uid) => {
    await admin.auth().getUser(uid);
    return admin.auth().createCustomToken(uid);
  },
});

const getFamilyAccounts = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  return { accounts: await service.getAccounts(request.auth.uid) };
});

const switchFamilyAccount = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  const customToken = await service.createSwitchToken(
    request.auth.uid,
    request.data?.targetSantriId,
  );
  return { customToken };
});

module.exports = {
  getFamilyAccounts,
  switchFamilyAccount,
  _private: {
    accountFromProfile,
    createFamilyAccountService,
    normalizedId,
    uniqueMemberIds,
  },
};
