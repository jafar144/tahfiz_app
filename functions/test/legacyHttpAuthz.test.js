"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

process.env.LEGACY_ADMIN_HTTP_ENABLED = "true";
// Meniru secret yang tersimpan dengan CRLF di ujung.
process.env.ADMIN_HTTP_TOKEN = "rahasia-uji\r\n";

const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

function fakeReq(headers) {
  const lower = Object.fromEntries(
    Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v]),
  );
  return { get: (name) => lower[name.toLowerCase()] };
}

function fakeRes() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
}

test("secret dengan CRLF di ujung tetap cocok dengan token header", () => {
  const res = fakeRes();
  assert.equal(
    authorizeLegacyAdminHttp(fakeReq({ "x-admin-token": "rahasia-uji" }), res),
    true,
  );
  assert.equal(res.statusCode, 200);
});

test("Bearer token juga diterima", () => {
  const res = fakeRes();
  assert.equal(
    authorizeLegacyAdminHttp(
      fakeReq({ authorization: "Bearer rahasia-uji" }),
      res,
    ),
    true,
  );
});

test("token salah atau kosong tetap ditolak 401", () => {
  for (const headers of [{ "x-admin-token": "salah" }, {}]) {
    const res = fakeRes();
    assert.equal(authorizeLegacyAdminHttp(fakeReq(headers), res), false);
    assert.equal(res.statusCode, 401);
  }
});
