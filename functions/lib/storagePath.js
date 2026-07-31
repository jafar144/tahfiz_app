const FIREBASE_STORAGE_HOSTS = new Set([
  "firebasestorage.googleapis.com",
  "storage.googleapis.com",
]);

// Ambil bucket dan path hanya dari URL download Firebase Storage yang valid:
// https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<ENCODED_PATH>?...
function storageObjectFromUrl(url) {
  try {
    const parsed = new URL(String(url));
    const isLocalEmulator =
      parsed.hostname === "localhost" ||
      parsed.hostname === "127.0.0.1" ||
      parsed.hostname === "::1";
    if (
      parsed.protocol !== "https:" &&
      !(parsed.protocol === "http:" && isLocalEmulator)
    ) {
      return null;
    }
    if (!FIREBASE_STORAGE_HOSTS.has(parsed.hostname) && !isLocalEmulator) {
      return null;
    }

    const match = parsed.pathname.match(
      /^\/(?:v0|download\/storage\/v1)\/b\/([^/]+)\/o\/(.+)$/,
    );
    if (!match) return null;
    return {
      bucket: decodeURIComponent(match[1]),
      path: decodeURIComponent(match[2]),
    };
  } catch (_) {
    return null;
  }
}

function storagePathFromUrl(url) {
  return storageObjectFromUrl(url)?.path || null;
}

module.exports = { storageObjectFromUrl, storagePathFromUrl };
