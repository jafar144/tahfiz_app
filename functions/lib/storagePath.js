// Ambil path objek Storage dari Firebase download URL:
// https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<ENCODED_PATH>?...
function storagePathFromUrl(url) {
  try {
    const match = String(url).match(/\/o\/([^?]+)/);
    return match ? decodeURIComponent(match[1]) : null;
  } catch (_) {
    return null;
  }
}

module.exports = { storagePathFromUrl };
