"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { db } = require("../lib/firebase");
const {
  loadFiqihMigrationPlan,
  writeFiqihCandidates,
} = require("../lib/fiqihMigration");

// Wajib diset sebelum deploy:
// firebase functions:secrets:set FIQIH_MIGRATION_TOKEN
const FIQIH_MIGRATION_TOKEN = defineSecret("FIQIH_MIGRATION_TOKEN");

const OPTIONS = {
  region: "asia-southeast2",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [FIQIH_MIGRATION_TOKEN],
};

function suppliedToken(req) {
  return String(req.query.token || (req.body && req.body.token) || "");
}

function applyRequested(req) {
  return req.query.apply === "true" || (req.body && req.body.apply === true);
}

exports.migrateSantriFiqihClasses = onRequest(OPTIONS, async (req, res) => {
  res.set("Cache-Control", "no-store");

  if (req.method !== "GET" && req.method !== "POST") {
    res.status(405).json({ error: "Gunakan GET atau POST." });
    return;
  }

  let expectedToken = "";
  try {
    expectedToken = FIQIH_MIGRATION_TOKEN.value();
  } catch (_) {}

  if (!expectedToken) {
    res.status(500).json({
      error:
        "FIQIH_MIGRATION_TOKEN belum diset. Jalankan firebase functions:secrets:set FIQIH_MIGRATION_TOKEN.",
    });
    return;
  }

  if (suppliedToken(req) !== expectedToken) {
    res.status(403).json({ error: "Token salah atau tidak ada." });
    return;
  }

  try {
    const apply = applyRequested(req);
    const plan = await loadFiqihMigrationPlan(db);

    if (!apply) {
      res.json({
        mode: "DRY-RUN",
        summary: plan.summary,
        message:
          "Tidak ada data diubah. Tambahkan apply=true untuk menjalankan migrasi.",
      });
      return;
    }

    if (plan.invalidExistingIds.length > 0) {
      res.status(409).json({
        error:
          "Migrasi dibatalkan karena ada nilai kelas_fiqih yang tidak dikenal.",
        summary: plan.summary,
      });
      return;
    }

    const written = await writeFiqihCandidates(db, plan.candidates);
    res.json({
      mode: "APPLY",
      summary: plan.summary,
      written,
      message: "Migrasi kelas Fiqih selesai.",
    });
  } catch (error) {
    console.error("migrateSantriFiqihClasses error:", error);
    res.status(500).json({ error: error.message || String(error) });
  }
});

module.exports._private = { applyRequested, suppliedToken };
