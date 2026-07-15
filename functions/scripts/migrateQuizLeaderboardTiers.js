"use strict";

process.env.GCLOUD_PROJECT ||= "khoirun-app";

const { admin, db } = require("../lib/firebase");
const { jakartaDateParts } = require("../lib/jakartaTime");
const {
  aggregateQuizAttempts,
  leaderboardCollectionId,
} = require("../lib/quizLeaderboardTiers");

function currentJakartaMonth() {
  const { year, month } = jakartaDateParts();
  return `${year}-${String(month).padStart(2, "0")}`;
}

function isMonthKey(value) {
  if (!/^\d{4}-\d{2}$/.test(value)) return false;
  const [year, month] = value.split("-").map(Number);
  return year >= 2000 && month >= 1 && month <= 12;
}

function nextMonthKey(monthKey) {
  const [year, month] = monthKey.split("-").map(Number);
  const date = new Date(Date.UTC(year, month, 1));
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(
    2,
    "0"
  )}`;
}

function parseArgs(args) {
  const options = {
    apply: false,
    monthKey: currentJakartaMonth(),
  };
  for (const arg of args) {
    if (arg === "--apply") {
      options.apply = true;
    } else if (arg.startsWith("--month=")) {
      options.monthKey = arg.slice("--month=".length);
    } else if (arg === "--help" || arg === "-h") {
      options.help = true;
    } else {
      throw new Error(`Argumen tidak dikenal: ${arg}`);
    }
  }
  if (!isMonthKey(options.monthKey)) {
    throw new Error(`Format bulan harus YYYY-MM: ${options.monthKey}`);
  }
  return options;
}

function usage() {
  return [
    "Migrasi leaderboard kuis dari histori Tantangan ke papan per tingkatan.",
    "",
    "Dry-run (default):",
    "  npm run migrate:quiz-leaderboards -- --month=2026-07",
    "",
    "Tulis ke Firestore:",
    "  npm run migrate:quiz-leaderboards -- --month=2026-07 --apply",
  ].join("\n");
}

function firestoreData(entry) {
  return {
    user_id: entry.userId,
    user_name: entry.userName,
    role: entry.role,
    month_key: entry.monthKey,
    mode: entry.mode,
    kelas: entry.studentClass,
    scope_kelas: entry.scopeClass,
    quiz_tier: entry.tier.key,
    quiz_tier_label: entry.tier.label,
    last_difficulty: entry.lastDifficulty,
    last_score: entry.lastScore,
    play_count: entry.playCount,
    best_score: entry.bestScore,
    best_difficulty: entry.bestDifficulty,
    best_at: admin.firestore.Timestamp.fromMillis(entry.bestAtMillis),
    updated_at: admin.firestore.Timestamp.fromMillis(entry.updatedAtMillis),
  };
}

async function loadAttempts(monthKey) {
  const nextMonth = nextMonthKey(monthKey);
  const snapshot = await db
    .collection("recitation_quiz_attempts")
    .where("date_key", ">=", `${monthKey}-01`)
    .where("date_key", "<", `${nextMonth}-01`)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() }));
}

async function writeEntries(entries) {
  const batchSize = 450;
  let written = 0;
  for (let start = 0; start < entries.length; start += batchSize) {
    const batch = db.batch();
    const chunk = entries.slice(start, start + batchSize);
    for (const entry of chunk) {
      const collectionId = leaderboardCollectionId(
        entry.mode,
        entry.tier.key
      );
      const ref = db
        .collection("quiz_leaderboards")
        .doc(entry.monthKey)
        .collection(collectionId)
        .doc(entry.userId);
      batch.set(ref, firestoreData(entry));
    }
    await batch.commit();
    written += chunk.length;
  }
  return written;
}

function summarize(entries) {
  const byBoard = {};
  for (const entry of entries) {
    const board = leaderboardCollectionId(entry.mode, entry.tier.key);
    byBoard[board] = (byBoard[board] || 0) + 1;
  }
  return byBoard;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(`${usage()}\n`);
    return;
  }

  process.stdout.write(
    `Membaca histori Tantangan bulan ${options.monthKey}...\n`
  );
  const attempts = await loadAttempts(options.monthKey);
  const result = aggregateQuizAttempts(attempts, {
    monthKey: options.monthKey,
  });
  const summary = {
    mode: options.apply ? "APPLY" : "DRY-RUN",
    month: options.monthKey,
    attemptsRead: attempts.length,
    attemptsAccepted: result.accepted,
    leaderboardDocuments: result.entries.length,
    boards: summarize(result.entries),
    skipped: result.skipped,
  };
  process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);

  if (!options.apply) {
    process.stdout.write(
      "Dry-run selesai; Firestore tidak diubah. Tambahkan --apply untuk menulis.\n"
    );
    return;
  }

  const written = await writeEntries(result.entries);
  process.stdout.write(
    `Selesai: ${written} dokumen leaderboard ditulis tanpa menghapus data lama.\n`
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
