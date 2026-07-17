const test = require("node:test");
const assert = require("node:assert/strict");

const {
  APP_FEATURE_KEYS,
  isSupportedAppFeature,
} = require("../lib/appFeatureConfig");

test("App Config hanya menerima feature key yang didukung", () => {
  assert.deepEqual(APP_FEATURE_KEYS, ["tahfiz_arena"]);
  assert.equal(isSupportedAppFeature("tahfiz_arena"), true);
  assert.equal(isSupportedAppFeature("fitur_tidak_dikenal"), false);
});
