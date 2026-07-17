const test = require("node:test");
const assert = require("node:assert/strict");

const { storagePathFromUrl } = require("../lib/storagePath");

test("download URL Firebase dikonversi ke path Storage", () => {
  const url =
    "https://firebasestorage.googleapis.com/v0/b/app/o/" +
    "syahadah_photos%2Fposter.jpg?alt=media&token=abc";

  assert.equal(storagePathFromUrl(url), "syahadah_photos/poster.jpg");
  assert.equal(storagePathFromUrl("bukan-url-storage"), null);
});
