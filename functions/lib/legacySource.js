// Sumber data sistem web lama untuk endpoint migrasi.
//
// GET  -> membaca langsung dari MySQL (perilaku awal).
// POST -> membaca tabel hasil export phpMyAdmin (JSON) di body:
//         { "tables": { "santris": [...], "users": [...],
//                       "payments": [...], "nilais": [...] } }
//         Setiap tabel boleh berupa array baris, atau array export
//         phpMyAdmin utuh ([header, database, {type:"table", data:[...]}]).
//         Jalur ini dipakai bila port MySQL hosting tidak dapat diakses.
//
// Semua nilai dikembalikan dalam bentuk seperti mysql2 `dateStrings: true`
// (tanggal = string "YYYY-MM-DD[ HH:MM:SS]") agar handler tidak bercabang.

const { createConnection } = require("./mysql");

// Kolom opsional tabel `users`. Kolom password/token tidak pernah dibaca.
const PHONE_COLUMNS = [
  "phone",
  "no_hp",
  "hp",
  "nohp",
  "telepon",
  "no_telp",
  "whatsapp",
  "no_wa",
];
const GENDER_COLUMNS = ["jenis_kelamin", "gender", "jk", "kelamin"];
const ROLE_COLUMNS = ["role", "level", "jabatan", "akses", "type"];
const CREATED_COLUMNS = ["created_at"];

function firstAvailable(columns, candidates) {
  return candidates.find((c) => columns.has(c)) || null;
}

function detectUserColumns(columns) {
  return {
    phoneCol: firstAvailable(columns, PHONE_COLUMNS),
    genderCol: firstAvailable(columns, GENDER_COLUMNS),
    roleCol: firstAvailable(columns, ROLE_COLUMNS),
    createdCol: firstAvailable(columns, CREATED_COLUMNS),
  };
}

function buildUsersSelect(columns) {
  const detected = detectUserColumns(columns);
  const parts = ["`id`", "`name`", "`username`"];
  if (detected.phoneCol) parts.push(`\`${detected.phoneCol}\` AS phone`);
  if (detected.genderCol) parts.push(`\`${detected.genderCol}\` AS gender`);
  if (detected.roleCol) parts.push(`\`${detected.roleCol}\` AS peran_web`);
  if (detected.createdCol) {
    parts.push(`\`${detected.createdCol}\` AS created_at`);
  }
  return { sql: `SELECT ${parts.join(", ")} FROM users`, detected };
}

function projectUserRow(row, detected) {
  const pick = (col) => (col && row[col] !== undefined ? row[col] : null);
  return {
    id: row.id,
    name: row.name,
    username: row.username,
    phone: pick(detected.phoneCol),
    gender: pick(detected.genderCol),
    peran_web: pick(detected.roleCol),
    created_at: pick(detected.createdCol),
  };
}

function periodIndex(tahun, bulan) {
  const y = parseInt(tahun, 10);
  const m = parseInt(bulan, 10);
  if (Number.isNaN(y) || Number.isNaN(m) || m < 1 || m > 12) return null;
  return y * 12 + (m - 1);
}

function inPeriod(row, year, startMonth) {
  return (
    parseInt(row.tahun, 10) === year && parseInt(row.bulan, 10) >= startMonth
  );
}

function indexToDate(index) {
  const year = Math.floor(index / 12);
  const month = (index % 12) + 1;
  return `${year}-${String(month).padStart(2, "0")}-01`;
}

// santri_id -> "YYYY-MM-01" bulan aktivitas paling awal (pembayaran apa pun
// statusnya atau penilaian). Dipakai sebagai tanggal masuk bila created_at
// kosong di web lama.
function firstActivityFromRows(payments, nilais) {
  const minIndex = new Map();
  for (const r of [...payments, ...nilais]) {
    if (r.santri_id == null) continue;
    const idx = periodIndex(r.tahun, r.bulan);
    if (idx == null) continue;
    const key = String(r.santri_id);
    if (!minIndex.has(key) || idx < minIndex.get(key)) minIndex.set(key, idx);
  }
  const result = new Map();
  for (const [key, idx] of minIndex) result.set(key, indexToDate(idx));
  return result;
}

function tableRows(value, name) {
  if (value == null) return null;
  if (!Array.isArray(value)) {
    throw new Error(`Tabel ${name} harus berupa array.`);
  }
  const exported = value.find(
    (x) => x && typeof x === "object" && x.type === "table",
  );
  if (exported) {
    if (!Array.isArray(exported.data)) {
      throw new Error(`Export phpMyAdmin tabel ${name} tidak berisi data.`);
    }
    return exported.data;
  }
  return value;
}

function parseUploadedTables(body) {
  const tables = body && typeof body === "object" ? body.tables : null;
  if (!tables || typeof tables !== "object") {
    throw new Error("Body POST wajib berisi { tables: {...} }.");
  }
  const result = {};
  for (const name of ["santris", "users", "payments", "nilais"]) {
    result[name] = tableRows(tables[name], name);
  }
  return result;
}

function requireTable(tables, name) {
  if (!tables[name]) {
    throw new Error(`Tabel ${name} wajib disertakan untuk endpoint ini.`);
  }
  return tables[name];
}

function createMemorySource(tables) {
  return {
    kind: "json",
    async santris() {
      return requireTable(tables, "santris");
    },
    async pembimbingRows() {
      return requireTable(tables, "santris")
        .filter((s) => s.pembimbing_id != null && s.pembimbing_id !== "")
        .map((s) => ({ pembimbing_id: s.pembimbing_id, golongan: s.golongan }));
    },
    async users() {
      const rows = requireTable(tables, "users");
      const columns = new Set();
      for (const r of rows) {
        for (const k of Object.keys(r)) columns.add(k.toLowerCase());
      }
      const detected = detectUserColumns(columns);
      return {
        rows: rows.map((r) => projectUserRow(r, detected)),
        detected,
      };
    },
    async paidPayments(year, startMonth) {
      return requireTable(tables, "payments").filter(
        (p) => String(p.status) === "1" && inPeriod(p, year, startMonth),
      );
    },
    async nilais(year, startMonth) {
      return requireTable(tables, "nilais").filter((n) =>
        inPeriod(n, year, startMonth),
      );
    },
    async operatorIds(year, startMonth) {
      const rows = await this.nilais(year, startMonth);
      return [
        ...new Set(
          rows
            .filter((n) => n.operator_id != null && n.operator_id !== "")
            .map((n) => String(n.operator_id)),
        ),
      ];
    },
    async firstActivityBySantri() {
      return firstActivityFromRows(
        tables.payments || [],
        tables.nilais || [],
      );
    },
    async close() {},
  };
}

function createMysqlSource(connection) {
  return {
    kind: "mysql",
    async santris() {
      const [rows] = await connection.execute(
        "SELECT id, nama, nis, tanggal_lahir, kelas, golongan, phone, tempat_lahir, status_spp, created_at FROM santris",
      );
      return rows;
    },
    async pembimbingRows() {
      const [rows] = await connection.execute(
        "SELECT pembimbing_id, golongan FROM santris WHERE pembimbing_id IS NOT NULL",
      );
      return rows;
    },
    async users() {
      const [columnRows] = await connection.execute(
        "SELECT COLUMN_NAME AS name FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'",
      );
      const columns = new Set(
        columnRows.map((c) => String(c.name || c.COLUMN_NAME).toLowerCase()),
      );
      const { sql, detected } = buildUsersSelect(columns);
      const [rows] = await connection.execute(sql);
      return { rows, detected };
    },
    async paidPayments(year, startMonth) {
      const [rows] = await connection.execute(
        "SELECT santri_id, bulan, tahun FROM payments WHERE status = 1 AND tahun = ? AND bulan >= ?",
        [year, startMonth],
      );
      return rows;
    },
    async nilais(year, startMonth) {
      const [rows] = await connection.execute(
        "SELECT santri_id, hafalan, perkembangan, akhlak, tahun, bulan, operator_id, created_at, updated_at FROM nilais WHERE tahun = ? AND bulan >= ?",
        [year, startMonth],
      );
      return rows;
    },
    async operatorIds(year, startMonth) {
      const [rows] = await connection.execute(
        "SELECT DISTINCT operator_id FROM nilais WHERE operator_id IS NOT NULL AND tahun = ? AND bulan >= ?",
        [year, startMonth],
      );
      return rows.map((r) => String(r.operator_id));
    },
    async firstActivityBySantri() {
      const [payments] = await connection.execute(
        "SELECT santri_id, MIN(tahun * 12 + bulan - 1) AS idx FROM payments GROUP BY santri_id",
      );
      const [nilais] = await connection.execute(
        "SELECT santri_id, MIN(tahun * 12 + bulan - 1) AS idx FROM nilais GROUP BY santri_id",
      );
      const toRows = (rows) =>
        rows
          .filter((r) => r.idx != null)
          .map((r) => ({
            santri_id: r.santri_id,
            tahun: Math.floor(Number(r.idx) / 12),
            bulan: (Number(r.idx) % 12) + 1,
          }));
      return firstActivityFromRows(toRows(payments), toRows(nilais));
    },
    async close() {
      await connection.end().catch(() => {});
    },
  };
}

async function openLegacySource(req) {
  if (req.method === "POST") {
    return createMemorySource(parseUploadedTables(req.body));
  }
  if (req.method !== "GET") {
    const error = new Error("Metode tidak didukung.");
    error.status = 405;
    throw error;
  }
  const connection = await createConnection({ dateStrings: true });
  return createMysqlSource(connection);
}

module.exports = {
  openLegacySource,
  _private: {
    buildUsersSelect,
    detectUserColumns,
    projectUserRow,
    firstActivityFromRows,
    parseUploadedTables,
    createMemorySource,
  },
};
