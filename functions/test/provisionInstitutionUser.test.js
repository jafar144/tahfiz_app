"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: {
    ASATIDZ_PASSWORD,
    dateOnly,
  },
} = require("../handlers/provisionInstitutionUser");
const { passwordFromBirthDate } = require("../lib/utils");

test("password semua akun asatidz selalu tetap", () => {
  assert.equal(ASATIDZ_PASSWORD, "Khoirun123");
});

test("password awal santri memakai tanggal lahir dalam urutan YYYYMMDD", () => {
  assert.equal(passwordFromBirthDate("2012-03-09"), "20120309");
});

test("tanggal provisioning wajib memakai format date-only", () => {
  const parsed = dateOnly("2012-03-09", "birthDate");
  assert.equal(parsed.text, "2012-03-09");
  assert.throws(() => dateOnly("09/03/2012", "birthDate"));
});
