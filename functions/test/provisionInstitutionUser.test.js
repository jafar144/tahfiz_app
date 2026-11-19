"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: {
    DEFAULT_ASATIDZ_INITIAL_PASSWORD,
    dateOnly,
  },
} = require("../handlers/provisionInstitutionUser");
const { asatidzInitialPassword } = require("../lib/config");
const { passwordFromBirthDate } = require("../lib/utils");

test("password asatidz default tetap Khoirun123 untuk project lama", () => {
  assert.equal(DEFAULT_ASATIDZ_INITIAL_PASSWORD, "Khoirun123");
  assert.equal(asatidzInitialPassword(""), "Khoirun123");
  assert.equal(asatidzInitialPassword(undefined), "Khoirun123");
});

test("password asatidz dapat diatur per lembaga", () => {
  assert.equal(asatidzInitialPassword("Jauhar123"), "Jauhar123");
  assert.equal(asatidzInitialPassword("  Jauhar123  "), "Jauhar123");
  assert.throws(() => asatidzInitialPassword("abc"));
});

test("password awal santri memakai tanggal lahir dalam urutan YYYYMMDD", () => {
  assert.equal(passwordFromBirthDate("2012-03-09"), "20120309");
});

test("tanggal provisioning wajib memakai format date-only", () => {
  const parsed = dateOnly("2012-03-09", "birthDate");
  assert.equal(parsed.text, "2012-03-09");
  assert.throws(() => dateOnly("09/03/2012", "birthDate"));
});
