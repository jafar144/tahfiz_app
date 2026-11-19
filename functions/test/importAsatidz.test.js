"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: {
    planAsatidzImport,
    normalizeGender,
    genderFromTitle,
    genderFromGolongan,
  },
} = require("../handlers/importAsatidz");

function plan(overrides = {}) {
  return planAsatidzImport({
    users: [],
    pembimbingRows: [],
    operatorIds: [],
    existingByNis: new Map(),
    emailDomain: "aljauhar.app",
    ...overrides,
  });
}

test("dengan kolom role, hanya role pengajar (1) yang diimpor", () => {
  const result = plan({
    users: [
      { id: 2, name: "Aljauhar", username: "Fahmi", peran_web: "0" },
      { id: 15, name: "Ust Hafizhon", username: "01001", peran_web: "1", phone: "6288" },
      { id: 19, name: "Ustadzah Aisyah", username: "01005", peran_web: "1" },
      { id: 28, name: "Test", username: "uji", peran_web: "0" },
    ],
    pembimbingRows: [{ pembimbing_id: "15", golongan: "Putra" }],
    // Admin web yang menginput nilai tetap bukan asatidz.
    operatorIds: ["2", "15"],
  });

  assert.deepEqual(result.toCreate.map((r) => r.nis), ["01001", "01005"]);
  assert.equal(result.toCreate[0].email, "01001@aljauhar.app");
  assert.equal(result.toCreate[0].phone, "6288");
  assert.equal(result.toCreate[0].jenis_kelamin, "L");
  assert.equal(result.toCreate[1].jenis_kelamin, "P");
  assert.deepEqual(
    result.notAsatidz.map((u) => [u.id, u.alasan, u.dirujuk]),
    [
      ["2", "role web 0 bukan pengajar", true],
      ["28", "role web 0 bukan pengajar", false],
    ],
  );
});

test("tanpa kolom role, asatidz = pembimbing atau operator penilaian", () => {
  const result = plan({
    users: [
      { id: 1, name: "Ust. Ahmad", username: "ahmad" },
      { id: 2, name: "Ust. Budi", username: "budi" },
      { id: 3, name: "Admin Web", username: "admin" },
    ],
    pembimbingRows: [
      { pembimbing_id: 1, golongan: "Putra Sore" },
      { pembimbing_id: 1, golongan: "Putra Malam" },
    ],
    operatorIds: [2],
  });

  assert.deepEqual(result.toCreate.map((r) => r.nis), ["ahmad", "budi"]);
  assert.equal(result.toCreate[0].jumlah_santri_bimbingan, 2);
  assert.equal(result.toCreate[1].operator_penilaian, true);
  assert.deepEqual(result.notAsatidz.map((u) => u.id), ["3"]);
});

test("akun yang sudah ada tidak dibuat ulang dan bentrok NIS santri dilaporkan", () => {
  const result = plan({
    users: [
      { id: 1, name: "Ust. Ahmad", username: "ahmad" },
      { id: 2, name: "Ust. Citra", username: "2024001" },
    ],
    operatorIds: [1, 2],
    existingByNis: new Map([
      ["ahmad", { uid: "u1", role: "asatidz" }],
      ["2024001", { uid: "u2", role: "santri" }],
    ]),
  });

  assert.equal(result.toCreate.length, 0);
  assert.deepEqual(
    result.skipped.map((s) => s.alasan),
    ["sudah ada di Firestore (skip)", "NIS sudah dipakai akun santri"],
  );
});

test("username kosong, tidak valid, atau ganda dilewati", () => {
  const result = plan({
    users: [
      { id: 1, name: "A", username: "" },
      { id: 2, name: "B", username: "ust budi" },
      { id: 3, name: "C", username: "Citra" },
      { id: 4, name: "C2", username: "citra" },
      { id: 5, name: "", username: "dina" },
    ],
    operatorIds: [1, 2, 3, 4, 5],
  });

  assert.deepEqual(result.toCreate.map((r) => r.nis), ["Citra"]);
  assert.deepEqual(
    result.skipped.map((s) => [s.id, s.alasan]),
    [
      ["1", "username kosong"],
      ["2", "username berisi karakter yang tidak didukung login"],
      ["4", "username ganda dengan users.id 3"],
      ["5", "nama kosong"],
    ],
  );
});

test("jenis kelamin: kolom web, lalu gelar, lalu golongan santri", () => {
  const result = plan({
    users: [
      { id: 1, name: "Rina", username: "rina", gender: "Perempuan" },
      { id: 2, name: "Ustadzah Suad", username: "suad" },
      { id: 3, name: "Pengajar Campur", username: "campur" },
      { id: 4, name: "Pengajar Putri", username: "putri" },
    ],
    pembimbingRows: [
      { pembimbing_id: 2, golongan: "Putra" },
      { pembimbing_id: 3, golongan: "Putra Pagi" },
      { pembimbing_id: 3, golongan: "Putri Sore" },
      { pembimbing_id: 4, golongan: "Putri" },
    ],
    operatorIds: [1],
  });

  assert.deepEqual(
    result.toCreate.map((r) => [r.nis, r.jenis_kelamin]),
    [["rina", "P"], ["suad", "P"], ["campur", ""], ["putri", "P"]],
  );
});

test("normalisasi jenis kelamin, gelar, dan golongan", () => {
  assert.equal(normalizeGender("laki-laki"), "L");
  assert.equal(normalizeGender("wanita"), "P");
  assert.equal(normalizeGender("x"), "");
  assert.equal(genderFromTitle("Ust Hafizhon"), "L");
  assert.equal(genderFromTitle("Ust. Ahmad"), "L");
  assert.equal(genderFromTitle("Ustadz Ali"), "L");
  assert.equal(genderFromTitle("Ustadzah Maryam"), "P");
  assert.equal(genderFromTitle("Aljauhar"), "");
  assert.equal(genderFromGolongan(["Putri Pagi", "Putri Malam"]), "P");
  assert.equal(genderFromGolongan([]), "");
});
