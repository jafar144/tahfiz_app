const {
  deleteApp,
  getApps,
  initializeApp,
} = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const {
  FieldValue,
  Timestamp,
  getFirestore,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getStorage } = require("firebase-admin/storage");

if (getApps().length === 0) {
  initializeApp();
}

// Compatibility facade untuk handler lama. Seluruh SDK diinisialisasi melalui
// API modular Firebase Admin v14, sementara migrasi tiap handler dapat dilakukan
// bertahap tanpa membawa kembali dependency namespace yang sudah dihapus.
const firestore = () => getFirestore();
firestore.FieldValue = FieldValue;
firestore.Timestamp = Timestamp;

const admin = {
  auth: () => getAuth(),
  firestore,
  messaging: () => getMessaging(),
  storage: () => getStorage(),
  get apps() {
    return getApps().map((app) => ({
      delete: () => deleteApp(app),
    }));
  },
};

const db = getFirestore();

module.exports = { admin, db };
