"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  classifyFiqihProfile,
  isFiqihEligibleClass,
} = require("../lib/fiqihClasses");
const { buildFiqihMigrationPlan } = require("../lib/fiqihMigration");

test("kelas fiqih hanya berlaku mulai Mutawassith", () => {
  assert.equal(isFiqihEligibleClass("Tahsin Awwal"), false);
  assert.equal(isFiqihEligibleClass("Tahsin Akhir"), false);
  assert.equal(isFiqihEligibleClass(" Mutawassith "), true);
  assert.equal(isFiqihEligibleClass("Takhossus Akhir"), true);
});

test("migrasi hanya mengisi profil aktif eligible yang masih kosong", () => {
  assert.equal(
    classifyFiqihProfile({ is_active: true, kelas: "Mutawassith" }),
    "needs_fiqih_1"
  );
  assert.equal(
    classifyFiqihProfile({ kelas: "Mutawassith" }),
    "needs_fiqih_1"
  );
  assert.equal(
    classifyFiqihProfile({
      is_active: true,
      kelas: "Mutawassith",
      kelas_fiqih: "Fiqih 2",
    }),
    "already_set"
  );
  assert.equal(
    classifyFiqihProfile({ is_active: false, kelas: "Takhossus Awal" }),
    "inactive"
  );
  assert.equal(
    classifyFiqihProfile({ is_active: true, kelas: "Tahsin Akhir" }),
    "ineligible_class"
  );
});

test("rencana migrasi tidak menimpa Fiqih yang sudah diatur", () => {
  const plan = buildFiqihMigrationPlan([
    { id: "a", data: { kelas: "Mutawassith" } },
    { id: "b", data: { kelas: "Takhossus Awal", kelas_fiqih: "Fiqih 2" } },
    { id: "c", data: { kelas: "Tahsin Akhir" } },
    { id: "d", data: { kelas: "Mutawassith", is_active: false } },
    { id: "e", data: { kelas: "Mutawassith", kelas_fiqih: "Tingkat 4" } },
  ]);

  assert.deepEqual(plan.candidates.map((entry) => entry.id), ["a"]);
  assert.equal(plan.summary.activeProfilesRead, 4);
  assert.equal(plan.summary.candidates, 1);
  assert.deepEqual(plan.invalidExistingIds, ["e"]);
});
