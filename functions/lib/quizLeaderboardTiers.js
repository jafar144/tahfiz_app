"use strict";

const QUIZ_TIERS = Object.freeze([
  Object.freeze({
    key: "juz_30",
    label: "Juz 30",
    scopeClass: "Mutawassith",
  }),
  Object.freeze({
    key: "pra_takhossus_awal",
    label: "Pra Takhossus Awal",
    scopeClass: "Pra Takhossus Awal",
  }),
  Object.freeze({
    key: "pra_takhossus_akhir",
    label: "Pra Takhossus Akhir",
    scopeClass: "Pra Takhossus Akhir",
  }),
  Object.freeze({
    key: "takhossus_awal",
    label: "Takhossus Awal",
    scopeClass: "Takhossus Awal",
  }),
]);

const TIERS_BY_KEY = new Map(QUIZ_TIERS.map((tier) => [tier.key, tier]));
const VALID_MODES = new Set(["voice", "choice"]);

function normalizeClassName(value) {
  return typeof value === "string"
    ? value.trim().toLowerCase().replace(/\s+/g, " ")
    : "";
}

const SCOPE_TO_TIER_KEY = new Map([
  ["mutawassith", "juz_30"],
  ["pra takhossus awal", "pra_takhossus_awal"],
  ["pra takhossus akhir", "pra_takhossus_akhir"],
  ["takhossus awal", "takhossus_awal"],
  ["takhossus tsani", "takhossus_awal"],
  ["takhossus tsalits", "takhossus_awal"],
  ["takhossus robi", "takhossus_awal"],
  ["takhossus khomis", "takhossus_awal"],
  ["takhossus akhir", "takhossus_awal"],
]);

function resolveQuizTier({ quizTier, scopeClass } = {}) {
  if (typeof quizTier === "string") {
    const explicit = TIERS_BY_KEY.get(quizTier.trim().toLowerCase());
    if (explicit) return explicit;
  }

  const key = SCOPE_TO_TIER_KEY.get(normalizeClassName(scopeClass));
  return key ? TIERS_BY_KEY.get(key) : null;
}

function leaderboardCollectionId(mode, tierKey) {
  if (!VALID_MODES.has(mode)) throw new Error(`Mode kuis tidak valid: ${mode}`);
  if (!TIERS_BY_KEY.has(tierKey)) {
    throw new Error(`Tingkatan kuis tidak valid: ${tierKey}`);
  }
  return `${mode}_${tierKey}`;
}

function monthFromDateKey(dateKey) {
  if (typeof dateKey !== "string") return null;
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey.trim());
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const probe = new Date(Date.UTC(year, month - 1, day));
  if (
    probe.getUTCFullYear() !== year ||
    probe.getUTCMonth() !== month - 1 ||
    probe.getUTCDate() !== day
  ) {
    return null;
  }
  return `${match[1]}-${match[2]}`;
}

function eventMillis(createdAt, dateKey) {
  if (createdAt && typeof createdAt.toMillis === "function") {
    const value = createdAt.toMillis();
    if (Number.isFinite(value)) return value;
  }
  if (createdAt instanceof Date && Number.isFinite(createdAt.getTime())) {
    return createdAt.getTime();
  }
  if (typeof createdAt === "number" && Number.isFinite(createdAt)) {
    return createdAt;
  }
  if (typeof createdAt === "string") {
    const value = Date.parse(createdAt);
    if (Number.isFinite(value)) return value;
  }
  if (monthFromDateKey(dateKey)) {
    return Date.parse(`${dateKey}T00:00:00+07:00`);
  }
  return null;
}

function asText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function incrementReason(reasons, reason) {
  reasons[reason] = (reasons[reason] || 0) + 1;
}

function aggregateQuizAttempts(attempts, { monthKey } = {}) {
  const entries = new Map();
  const skipped = {};
  let accepted = 0;

  for (const raw of attempts) {
    const data = raw && raw.data && typeof raw.data === "object"
      ? raw.data
      : raw;
    const sourceId = asText(raw && raw.id) || asText(data && data.id);
    if (!data || data.kind !== "challenge") {
      incrementReason(skipped, "not_challenge");
      continue;
    }

    const attemptMonth = monthFromDateKey(data.date_key);
    if (!attemptMonth) {
      incrementReason(skipped, "invalid_date");
      continue;
    }
    if (monthKey && attemptMonth !== monthKey) {
      incrementReason(skipped, "other_month");
      continue;
    }

    const userId = asText(data.user_id);
    if (!userId) {
      incrementReason(skipped, "missing_user");
      continue;
    }
    const mode = asText(data.mode).toLowerCase();
    if (!VALID_MODES.has(mode)) {
      incrementReason(skipped, "invalid_mode");
      continue;
    }
    const tier = resolveQuizTier({
      quizTier: data.quiz_tier,
      scopeClass: data.scope_kelas,
    });
    if (!tier) {
      incrementReason(skipped, "invalid_tier");
      continue;
    }
    const score = Number(data.score);
    if (!Number.isFinite(score)) {
      incrementReason(skipped, "invalid_score");
      continue;
    }
    const atMillis = eventMillis(data.created_at, data.date_key);
    if (atMillis == null) {
      incrementReason(skipped, "invalid_timestamp");
      continue;
    }

    accepted += 1;
    const entryKey = [attemptMonth, mode, tier.key, userId].join("|");
    let entry = entries.get(entryKey);
    if (!entry) {
      entry = {
        monthKey: attemptMonth,
        mode,
        tier,
        userId,
        userName: "",
        role: "",
        studentClass: "",
        scopeClass: "",
        lastDifficulty: "easy",
        lastScore: 0,
        playCount: 0,
        bestScore: -1,
        bestDifficulty: "easy",
        bestAtMillis: null,
        updatedAtMillis: null,
        _lastSourceId: "",
        _bestSourceId: "",
      };
      entries.set(entryKey, entry);
    }

    entry.playCount += 1;
    const difficulty = asText(data.difficulty) || "easy";
    const isLatest =
      entry.updatedAtMillis == null ||
      atMillis > entry.updatedAtMillis ||
      (atMillis === entry.updatedAtMillis && sourceId > entry._lastSourceId);
    if (isLatest) {
      entry.userName = asText(data.user_name) || entry.userName;
      entry.role = asText(data.role) || entry.role;
      entry.studentClass = asText(data.kelas) || entry.studentClass;
      entry.scopeClass = asText(data.scope_kelas) || tier.scopeClass;
      entry.lastDifficulty = difficulty;
      entry.lastScore = Math.trunc(score);
      entry.updatedAtMillis = atMillis;
      entry._lastSourceId = sourceId;
    }

    const isEarlierTie =
      score === entry.bestScore &&
      (entry.bestAtMillis == null ||
        atMillis < entry.bestAtMillis ||
        (atMillis === entry.bestAtMillis && sourceId < entry._bestSourceId));
    if (score > entry.bestScore || isEarlierTie) {
      entry.bestScore = Math.trunc(score);
      entry.bestDifficulty = difficulty;
      entry.bestAtMillis = atMillis;
      entry._bestSourceId = sourceId;
    }
  }

  const resultEntries = [...entries.values()]
    .map(({ _lastSourceId, _bestSourceId, ...entry }) => entry)
    .sort((a, b) => {
      const pathA = `${a.monthKey}/${a.mode}/${a.tier.key}/${a.userId}`;
      const pathB = `${b.monthKey}/${b.mode}/${b.tier.key}/${b.userId}`;
      return pathA.localeCompare(pathB);
    });

  return { entries: resultEntries, accepted, skipped };
}

module.exports = {
  QUIZ_TIERS,
  aggregateQuizAttempts,
  leaderboardCollectionId,
  monthFromDateKey,
  resolveQuizTier,
};
