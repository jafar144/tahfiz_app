const test = require("node:test");
const assert = require("node:assert/strict");

const {
  storageObjectFromUrl,
  storagePathFromUrl,
} = require("../lib/storagePath");

test("download URL Firebase dikonversi ke path Storage", () => {
  const url =
    "https://firebasestorage.googleapis.com/v0/b/app/o/" +
    "syahadah_photos%2Fposter.jpg?alt=media&token=abc";

  assert.equal(storagePathFromUrl(url), "syahadah_photos/poster.jpg");
  assert.equal(storagePathFromUrl("bukan-url-storage"), null);
});

test("URL dengan host palsu ditolak walaupun memiliki pola /o/", () => {
  const url =
    "https://evil.example/v0/b/demo.appspot.com/o/" +
    "syahadah_photos%2Fposter.jpg?alt=media";
  assert.equal(storageObjectFromUrl(url), null);
  assert.equal(storagePathFromUrl(url), null);
});

test("bucket dan path Firebase Storage dapat divalidasi terpisah", () => {
  const url =
    "https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/" +
    "syahadah_photos%2Fposter.jpg?alt=media";
  assert.deepEqual(storageObjectFromUrl(url), {
    bucket: "demo.appspot.com",
    path: "syahadah_photos/poster.jpg",
  });
});
