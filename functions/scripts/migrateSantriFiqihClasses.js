"use strict";

if (!process.env.GCLOUD_PROJECT && !process.env.GOOGLE_CLOUD_PROJECT) {
  throw new Error(
    "Set GCLOUD_PROJECT secara eksplisit agar migrasi tidak salah project.",
  );
}

const { admin, db } = require("../lib/firebase");
const {
  loadFiqihMigrationPlan,
  writeFiqihCandidates,
} = require("../lib/fiqihMigration");

function parseArgs(args) {
  const options = { apply: false };
  for (const arg of args) {
    if (arg === "--apply") {
      options.apply = true;
    } else if (arg === "--help" || arg === "-h") {
      options.help = true;
    } else {
      throw new Error(`Argumen tidak dikenal: ${arg}`);
    }
  }
  return options;
}

function usage() {
  return [
    "Isi kelas_fiqih=Fiqih 1 untuk santri aktif mulai kelas Mutawassith.",
    "Nilai Fiqih yang sudah ada tidak pernah ditimpa.",
    "",
    "Dry-run (default):",
    "  npm run migrate:santri-fiqih",
    "",
    "Tulis ke Firestore:",
    "  npm run migrate:santri-fiqih -- --apply",
  ].join("\n");
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(`${usage()}\n`);
    return;
  }

  const plan = await loadFiqihMigrationPlan(db);

  const summary = {
    mode: options.apply ? "APPLY" : "DRY-RUN",
    ...plan.summary,
    invalidExistingIds: plan.invalidExistingIds,
  };
  process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);

  if (!options.apply) {
    process.stdout.write(
      "Dry-run selesai; Firestore tidak diubah. Tambahkan --apply untuk menulis.\n"
    );
    return;
  }

  if (plan.invalidExistingIds.length > 0) {
    throw new Error(
      "Migrasi dibatalkan: ada nilai kelas_fiqih tidak dikenal. Periksa ringkasan."
    );
  }

  const written = await writeFiqihCandidates(db, plan.candidates);
  process.stdout.write(
    `Selesai: ${written} profil santri diisi kelas_fiqih=Fiqih 1.\n`
  );
}

main()
  .catch((error) => {
    process.stderr.write(`${error.stack || error}\n`);
    process.exitCode = 1;
  })
  .finally(async () => {
    await Promise.all(admin.apps.map((app) => app.delete()));
  });
