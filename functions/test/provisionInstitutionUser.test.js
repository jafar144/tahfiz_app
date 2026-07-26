"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: {
    dateOnly,
    randomTemporaryPassword,
    staffInitialPassword,
  },
} = require("../handlers/provisionInstitutionUser");
const { passwordFromBirthDate } = require("../lib/utils");

test("password sementara pengguna acak, panjang, dan mudah disalin", () => {
  const first = randomTemporaryPassword();
  const second = randomTemporaryPassword();
  assert.equal(first.length, 16);
  assert.equal(second.length, 16);
  assert.notEqual(first, second);
  assert.match(first, /^[A-Za-z0-9!@#$]+$/);
});

test("password awal staff dapat ditetapkan per lembaga", () => {
  assert.equal(staffInitialPassword("Barokatul123"), "Barokatul123");
  assert.equal(staffInitialPassword("").length, 16);
  assert.throws(() => staffInitialPassword("terlalulemah"));
});

test("password awal santri memakai tanggal lahir dalam urutan YYYYMMDD", () => {
  assert.equal(passwordFromBirthDate("2012-03-09"), "20120309");
});

test("tanggal provisioning wajib memakai format date-only", () => {
  const parsed = dateOnly("2012-03-09", "birthDate");
  assert.equal(parsed.text, "2012-03-09");
  assert.throws(() => dateOnly("09/03/2012", "birthDate"));
});
