"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  aggregateQuizAttempts,
  leaderboardCollectionId,
  resolveQuizTier,
} = require("../lib/quizLeaderboardTiers");

function attempt({
  id,
  userId = "santri-a",
  kelas = "Takhossus Tsalits",
  scope = "Takhossus Tsalits",
  mode = "voice",
  score,
  dateKey = "2026-07-10",
  createdAt,
  difficulty = "medium",
  kind = "challenge",
}) {
  return {
    id,
    data: {
      kind,
      user_id: userId,
      user_name: userId === "santri-a" ? "Ahmad" : "Bilal",
      role: "santri",
      kelas,
      scope_kelas: scope,
      mode,
      difficulty,
      score,
      date_key: dateKey,
      created_at: new Date(createdAt),
    },
  };
}

test("kelas kurikulum dipetakan ke empat tingkatan kuis canonical", () => {
  assert.equal(resolveQuizTier({ scopeClass: "Mutawassith" }).key, "juz_30");
  assert.equal(
    resolveQuizTier({ scopeClass: "Pra Takhossus Awal" }).key,
    "pra_takhossus_awal"
  );
  assert.equal(
    resolveQuizTier({ scopeClass: "Pra Takhossus Akhir" }).key,
    "pra_takhossus_akhir"
  );
  assert.equal(
    resolveQuizTier({ scopeClass: "Takhossus Tsalits" }).key,
    "takhossus_awal"
  );
  assert.equal(resolveQuizTier({ scopeClass: "Tahsin Akhir" }), null);
  assert.equal(
    leaderboardCollectionId("voice", "takhossus_awal"),
    "voice_takhossus_awal"
  );
});

test("skor terbaik dipisah per tingkatan meski user dan bulan sama", () => {
  const result = aggregateQuizAttempts(
    [
      attempt({
        id: "a-later",
        score: 70,
        createdAt: "2026-07-12T01:00:00Z",
      }),
      attempt({
        id: "a-best",
        score: 88,
        createdAt: "2026-07-10T01:00:00Z",
      }),
      attempt({
        id: "a-juz30",
        kelas: "Takhossus Tsalits",
        scope: "Mutawassith",
        score: 95,
        createdAt: "2026-07-11T01:00:00Z",
      }),
      attempt({
        id: "b-choice",
        userId: "santri-b",
        kelas: "Pra Takhossus Awal",
        scope: "Pra Takhossus Awal",
        mode: "choice",
        score: 120,
        createdAt: "2026-07-11T02:00:00Z",
      }),
    ],
    { monthKey: "2026-07" }
  );

  assert.equal(result.accepted, 4);
  assert.equal(result.entries.length, 3);
  const takhossus = result.entries.find(
    (entry) =>
      entry.userId === "santri-a" && entry.tier.key === "takhossus_awal"
  );
  const juz30 = result.entries.find(
    (entry) => entry.userId === "santri-a" && entry.tier.key === "juz_30"
  );
  assert.equal(takhossus.playCount, 2);
  assert.equal(takhossus.bestScore, 88);
  assert.equal(takhossus.lastScore, 70);
  assert.equal(juz30.playCount, 1);
  assert.equal(juz30.bestScore, 95);
});

test("tie-break mempertahankan waktu skor terbaik yang lebih awal", () => {
  const result = aggregateQuizAttempts(
    [
      attempt({
        id: "late",
        score: 90,
        difficulty: "hard",
        createdAt: "2026-07-15T03:00:00Z",
      }),
      attempt({
        id: "early",
        score: 90,
        difficulty: "easy",
        createdAt: "2026-07-14T03:00:00Z",
      }),
    ],
    { monthKey: "2026-07" }
  );
  const entry = result.entries[0];
  assert.equal(entry.bestScore, 90);
  assert.equal(entry.bestDifficulty, "easy");
  assert.equal(entry.bestAtMillis, Date.parse("2026-07-14T03:00:00Z"));
  assert.equal(entry.lastDifficulty, "hard");
});

test("latihan, bulan lain, dan cakupan tidak dikenal tidak ikut migrasi", () => {
  const result = aggregateQuizAttempts(
    [
      attempt({
        id: "practice",
        score: 10,
        kind: "practice",
        createdAt: "2026-07-10T01:00:00Z",
      }),
      attempt({
        id: "old",
        score: 20,
        dateKey: "2026-06-10",
        createdAt: "2026-06-10T01:00:00Z",
      }),
      attempt({
        id: "unknown",
        score: 30,
        scope: "Tahsin Akhir",
        createdAt: "2026-07-10T01:00:00Z",
      }),
    ],
    { monthKey: "2026-07" }
  );
  assert.equal(result.accepted, 0);
  assert.equal(result.entries.length, 0);
  assert.deepEqual(result.skipped, {
    not_challenge: 1,
    other_month: 1,
    invalid_tier: 1,
  });
});
