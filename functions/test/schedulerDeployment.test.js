const test = require("node:test");
const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const path = require("node:path");

function manifest(projectId) {
  const env = { ...process.env, DEPLOY_LEGACY_HTTP_FUNCTIONS: "false" };
  delete env.GCLOUD_PROJECT;
  delete env.GOOGLE_CLOUD_PROJECT;
  if (projectId) env.GCLOUD_PROJECT = projectId;
  const script = `
    const entries = Object.entries(require('./index'));
    console.log(JSON.stringify({
      schedules: entries.filter(([, f]) => f.__endpoint?.scheduleTrigger).map(([name]) => name),
      active: entries.filter(([, f]) => !f.__endpoint?.scheduleTrigger).map(([name]) => name)
    }));
  `;
  return JSON.parse(execFileSync(process.execPath, ["-e", script], {
    cwd: path.resolve(__dirname, ".."), env, encoding: "utf8",
  }).trim());
}

test("project lama tetap tiga scheduler; Al-Jauhar tanpa scheduler dan tanpa endpoint migrasi", () => {
  const original = manifest(undefined);
  assert.deepEqual(original.schedules, [
    "notifyAssessmentWindowOpen", "notifyArrearsMonthEnd", "cleanupExpiredSyahadah",
  ]);
  const deferred = manifest("al-jauhar-app");
  assert.deepEqual(deferred.schedules, []);
  // Migrasi MySQL Al-Jauhar selesai 19 Nov 2026: endpoint legacy tidak
  // boleh ikut terpasang lagi pada deploy berikutnya.
  const legacyMigrationEndpoints = [
    "compareSantri", "checkBirthDates", "resetSantriPasswords", "importSantri",
    "importAsatidz", "importPayments", "importMonthlyReports", "migrateSantriFiqihClasses",
    "groupPengajarSantri",
  ];
  assert.deepEqual(deferred.active, original.active);
  for (const name of legacyMigrationEndpoints) {
    assert.ok(!deferred.active.includes(name), name);
    assert.ok(!original.active.includes(name), name);
  }
  assert.ok(deferred.active.includes("provisionInstitutionUser"));
  assert.ok(deferred.active.includes("transcribeRecitation"));
  assert.ok(deferred.active.includes("sendScheduledPaymentWhatsApp"));
  assert.deepEqual(manifest("khoirun-app").schedules, original.schedules);
  const barokatul = manifest("barokatul-apps");
  assert.deepEqual(barokatul.schedules, []);
  assert.ok(barokatul.active.includes("provisionInstitutionUser"));
  assert.ok(!barokatul.active.includes("transcribeRecitation"));
  assert.ok(!barokatul.active.includes("getPaymentReminderSchedule"));
  assert.ok(!barokatul.active.includes("sendManualPaymentReminder"));
  assert.ok(!barokatul.active.includes("sendScheduledPaymentWhatsApp"));
});
