"use strict";

const { classifyFiqihProfile } = require("./fiqihClasses");

function increment(map, key) {
  map[key] = (map[key] || 0) + 1;
}

function displayClassName(value) {
  return typeof value === "string" && value.trim()
    ? value.trim()
    : "(tanpa kelas)";
}

function buildFiqihMigrationPlan(entries) {
  const candidates = [];
  const statusCounts = {};
  const candidatesByClass = {};
  const invalidExistingIds = [];
  let activeProfilesRead = 0;

  for (const entry of entries) {
    const data = entry.data || {};
    const status = classifyFiqihProfile(data);
    increment(statusCounts, status);

    if (status !== "inactive") activeProfilesRead += 1;

    if (status === "needs_fiqih_1") {
      candidates.push(entry);
      increment(candidatesByClass, displayClassName(data.kelas));
    } else if (status === "invalid_existing_value") {
      invalidExistingIds.push(entry.id);
    }
  }

  return {
    candidates,
    invalidExistingIds,
    summary: {
      profilesRead: entries.length,
      activeProfilesRead,
      candidates: candidates.length,
      statusCounts,
      candidatesByClass,
      invalidExistingCount: invalidExistingIds.length,
    },
  };
}

async function loadFiqihMigrationPlan(db) {
  const snapshot = await db.collection("santri_profiles").get();
  return buildFiqihMigrationPlan(
    snapshot.docs.map((doc) => ({ id: doc.id, ref: doc.ref, data: doc.data() }))
  );
}

async function writeFiqihCandidates(db, candidates) {
  const batchSize = 450;
  let written = 0;
  for (let start = 0; start < candidates.length; start += batchSize) {
    const batch = db.batch();
    const chunk = candidates.slice(start, start + batchSize);
    for (const candidate of chunk) {
      batch.update(candidate.ref, { kelas_fiqih: "Fiqih 1" });
    }
    await batch.commit();
    written += chunk.length;
  }
  return written;
}

module.exports = {
  buildFiqihMigrationPlan,
  loadFiqihMigrationPlan,
  writeFiqihCandidates,
};
