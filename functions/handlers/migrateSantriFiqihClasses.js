"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const { db } = require("../lib/firebase");
const { LEGACY_ADMIN_HTTP_OPTIONS } = require("../lib/legacyConfig");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");
const {
  loadFiqihMigrationPlan,
  writeFiqihCandidates,
} = require("../lib/fiqihMigration");

function applyRequested(req) {
  return req.query.apply === "true" || (req.body && req.body.apply === true);
}

exports.migrateSantriFiqihClasses = onRequest(
  LEGACY_ADMIN_HTTP_OPTIONS,
  async (req, res) => {
    res.set("Cache-Control", "no-store");
    if (!authorizeLegacyAdminHttp(req, res)) return;

    if (req.method !== "GET" && req.method !== "POST") {
      res.status(405).json({ error: "Gunakan GET atau POST." });
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
  },
);

module.exports._private = { applyRequested };
