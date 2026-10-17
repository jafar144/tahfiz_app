"use strict";

const CLASS_ALIASES = new Map([
  ["Takhossus Rabi", "Takhossus Robi"],
]);

const PROMOTIONS = new Map([
  [
    "Tahsin Awwal",
    { milestoneNumber: 3, hafalan: "Iqro' 3", toClass: "Tahsin Akhir" },
  ],
  [
    "Tahsin Akhir",
    { milestoneNumber: 6, hafalan: "Iqro' 6", toClass: "Mutawassith" },
  ],
  [
    "Mutawassith",
    { milestoneNumber: 25, hafalan: "JUZ 30", toClass: "Pra Takhossus Awal" },
  ],
  [
    "Pra Takhossus Awal",
    {
      milestoneNumber: 32,
      hafalan: "PRA TAKHOSSUS AWWAL",
      toClass: "Pra Takhossus Akhir",
    },
  ],
  [
    "Pra Takhossus Akhir",
    {
      milestoneNumber: 38,
      hafalan: "PRA TAKHOSSUS AKHIR",
      toClass: "Takhossus Awal",
    },
  ],
  [
    "Takhossus Awal",
    { milestoneNumber: 45, hafalan: "JUZ 1-5", toClass: "Takhossus Tsani" },
  ],
  [
    "Takhossus Tsani",
    {
      milestoneNumber: 51,
      hafalan: "JUZ 1-10",
      toClass: "Takhossus Tsalits",
    },
  ],
  [
    "Takhossus Tsalits",
    { milestoneNumber: 57, hafalan: "JUZ 1-15", toClass: "Takhossus Robi" },
  ],
  [
    "Takhossus Robi",
    { milestoneNumber: 63, hafalan: "JUZ 1-20", toClass: "Takhossus Khomis" },
  ],
  [
    "Takhossus Khomis",
    { milestoneNumber: 69, hafalan: "JUZ 1-25", toClass: "Takhossus Akhir" },
  ],
]);

function normalizeGraduationClass(value) {
  const normalized = String(value || "").trim();
  return CLASS_ALIASES.get(normalized) || normalized;
}

function resolveGraduationPromotion({
  fromClass,
  toClass,
  milestoneNumber,
  hafalan,
}) {
  const normalizedFrom = normalizeGraduationClass(fromClass);
  const normalizedTo = normalizeGraduationClass(toClass);
  const expected = PROMOTIONS.get(normalizedFrom);
  if (
    !expected ||
    normalizedTo !== expected.toClass ||
    Number(milestoneNumber) !== expected.milestoneNumber ||
    String(hafalan || "").trim() !== expected.hafalan
  ) {
    return null;
  }
  return {
    fromClass: normalizedFrom,
    toClass: expected.toClass,
    milestoneNumber: expected.milestoneNumber,
  };
}

module.exports = {
  normalizeGraduationClass,
  resolveGraduationPromotion,
};
