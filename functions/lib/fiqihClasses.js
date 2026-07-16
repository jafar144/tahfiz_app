"use strict";

const FIQIH_CLASSES = Object.freeze(["Fiqih 1", "Fiqih 2", "Fiqih 3"]);
const ELIGIBLE_SANTRI_CLASSES = Object.freeze([
  "Mutawassith",
  "Pra Takhossus Awal",
  "Pra Takhossus Akhir",
  "Takhossus Awal",
  "Takhossus Tsani",
  "Takhossus Tsalits",
  "Takhossus Robi",
  "Takhossus Khomis",
  "Takhossus Akhir",
]);

function normalizeClassName(value) {
  return typeof value === "string"
    ? value.trim().toLowerCase().replace(/\s+/g, " ")
    : "";
}

const ELIGIBLE_CLASS_KEYS = new Set(
  ELIGIBLE_SANTRI_CLASSES.map(normalizeClassName)
);
const FIQIH_CLASS_KEYS = new Set(FIQIH_CLASSES.map(normalizeClassName));

function isFiqihEligibleClass(value) {
  return ELIGIBLE_CLASS_KEYS.has(normalizeClassName(value));
}

function classifyFiqihProfile(data = {}) {
  if (data.is_active === false) return "inactive";
  if (!isFiqihEligibleClass(data.kelas)) return "ineligible_class";

  const current = normalizeClassName(data.kelas_fiqih);
  if (!current) return "needs_fiqih_1";
  if (FIQIH_CLASS_KEYS.has(current)) return "already_set";
  return "invalid_existing_value";
}

module.exports = {
  ELIGIBLE_SANTRI_CLASSES,
  FIQIH_CLASSES,
  classifyFiqihProfile,
  isFiqihEligibleClass,
  normalizeClassName,
};
