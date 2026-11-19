"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  openLegacySource,
  _private: {
    buildUsersSelect,
    firstActivityFromRows,
    parseUploadedTables,
  },
} = require("../lib/legacySource");
const {
  _private: { resolveEntryDate },
} = require("../handlers/importSantri");

function phpMyAdminExport(name, data) {
  return [
    { type: "header", version: "5.2.3" },
    { type: "database", name: "lttm2936_jauhar" },
    { type: "table", name, database: "lttm2936_jauhar", data },
  ];
}

const tables = {
  santris: phpMyAdminExport("santris", [
    { id: "2", nama: "A", nis: "002", golongan: "Putra", pembimbing_id: "17", created_at: null },
    { id: "3", nama: "B", nis: "003", golongan: "Putri", pembimbing_id: "", created_at: "2026-07-06 09:10:40" },
  ]),
  users: phpMyAdminExport("users", [
    { id: "17", name: "Ust A", username: "01003", password: "$2y$hash", remember_token: "x", phone: "628", role: "1", created_at: "2025-05-20 13:02:13" },
  ]),
  payments: [
    { santri_id: "2", bulan: "5", tahun: "2025", status: "1" },
    { santri_id: "2", bulan: "4", tahun: "2026", status: "1" },
    { santri_id: "2", bulan: "3", tahun: "2026", status: "1" },
    { santri_id: "3", bulan: "5", tahun: "2026", status: "0" },
  ],
  nilais: phpMyAdminExport("nilais", [
    { santri_id: "2", bulan: "4", tahun: "2026", operator_id: "17" },
    { santri_id: "3", bulan: "4", tahun: "2025", operator_id: "17" },
  ]),
};

test("POST memakai tabel export phpMyAdmin tanpa koneksi MySQL", async () => {
  const source = await openLegacySource({ method: "POST", body: { tables } });
  assert.equal(source.kind, "json");
  assert.equal((await source.santris()).length, 2);
  assert.deepEqual(await source.pembimbingRows(), [
    { pembimbing_id: "17", golongan: "Putra" },
  ]);

  const { rows, detected } = await source.users();
  assert.deepEqual(rows, [{
    id: "17", name: "Ust A", username: "01003", phone: "628",
    gender: null, peran_web: "1", created_at: "2025-05-20 13:02:13",
  }]);
  assert.equal(detected.roleCol, "role");
  assert.ok(!("password" in rows[0]));

  // Hanya status 1 pada tahun target, mulai bulan target.
  assert.deepEqual(
    (await source.paidPayments(2026, 4)).map((p) => p.bulan),
    ["4"],
  );
  assert.equal((await source.nilais(2026, 4)).length, 1);
  assert.deepEqual(await source.operatorIds(2026, 4), ["17"]);
  await source.close();
});

test("tabel yang tidak dikirim ditolak dengan pesan jelas", async () => {
  const source = await openLegacySource({
    method: "POST",
    body: { tables: { santris: [] } },
  });
  await assert.rejects(() => source.users(), /Tabel users wajib/);
  assert.throws(() => parseUploadedTables({}), /tables/);
  assert.throws(
    () => parseUploadedTables({ tables: { santris: {} } }),
    /harus berupa array/,
  );
});

test("aktivitas pertama memakai bulan pembayaran/penilaian paling awal", () => {
  const first = firstActivityFromRows(tables.payments, tables.nilais[2].data);
  assert.equal(first.get("2"), "2025-05-01");
  assert.equal(first.get("3"), "2025-04-01");
});

test("tanggal masuk: created_at, lalu aktivitas pertama, lalu kosong", () => {
  const first = new Map([["2", "2025-05-01"]]);
  assert.deepEqual(
    resolveEntryDate({ id: "3", created_at: "2026-07-06 09:10:40" }, first),
    { value: "2026-07-06 09:10:40", source: "created_at" },
  );
  assert.deepEqual(
    resolveEntryDate({ id: "2", created_at: null }, first),
    { value: "2025-05-01", source: "aktivitas_pertama" },
  );
  assert.deepEqual(
    resolveEntryDate({ id: "9", created_at: null }, first),
    { value: null, source: "kosong" },
  );
});

test("query users MySQL hanya memakai kolom aman yang terdeteksi", () => {
  const { sql, detected } = buildUsersSelect(
    new Set(["id", "name", "username", "password", "no_hp", "level"]),
  );
  assert.equal(
    sql,
    "SELECT `id`, `name`, `username`, `no_hp` AS phone, `level` AS peran_web FROM users",
  );
  assert.equal(detected.genderCol, null);
  assert.ok(!sql.includes("password"));
});

test("metode selain GET/POST ditolak", async () => {
  await assert.rejects(
    () => openLegacySource({ method: "DELETE" }),
    (err) => err.status === 405,
  );
});
