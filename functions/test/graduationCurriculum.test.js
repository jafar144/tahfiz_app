"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  normalizeGraduationClass,
  resolveGraduationPromotion,
} = require("../lib/graduationCurriculum");

test("promotion hanya valid pada capaian terakhir kelas", () => {
  assert.deepEqual(
    resolveGraduationPromotion({
      fromClass: "Mutawassith",
      toClass: "Pra Takhossus Awal",
      milestoneNumber: 25,
      hafalan: "JUZ 30",
    }),
    {
      fromClass: "Mutawassith",
      toClass: "Pra Takhossus Awal",
      milestoneNumber: 25,
    },
  );
  assert.equal(
    resolveGraduationPromotion({
      fromClass: "Mutawassith",
      toClass: "Pra Takhossus Awal",
      milestoneNumber: 23,
      hafalan: "An Naba'",
    }),
    null,
  );
});

test("target kelas dan label capaian tidak dapat dimanipulasi", () => {
  assert.equal(
    resolveGraduationPromotion({
      fromClass: "Mutawassith",
      toClass: "Takhossus Akhir",
      milestoneNumber: 24,
      hafalan: "JUZ 30",
    }),
    null,
  );
  assert.equal(
    resolveGraduationPromotion({
      fromClass: "Mutawassith",
      toClass: "Pra Takhossus Awal",
      milestoneNumber: 24,
      hafalan: "JUZ 29",
    }),
    null,
  );
});

test("alias Rabi mengikuti kelas canonical Robi", () => {
  assert.equal(normalizeGraduationClass("Takhossus Rabi"), "Takhossus Robi");
  assert.equal(
    resolveGraduationPromotion({
      fromClass: "Takhossus Rabi",
      toClass: "Takhossus Khomis",
      milestoneNumber: 63,
      hafalan: "JUZ 1-20",
    })?.fromClass,
    "Takhossus Robi",
  );
});
