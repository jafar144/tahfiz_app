# App Config

App Config menyimpan feature flag runtime di Firestore:

- Collection: `app_config`
- Document: `runtime`
- Field: `features.<feature_key>`

Contoh:

```json
{
  "features": {
    "tahfiz_arena": true
  }
}
```

Jika dokumen atau sebuah key belum ada, aplikasi memakai nilai default dari
`AppFeature.defaultEnabled`. Perubahan dilakukan melalui callable function
`setAppFeatureConfig`, yang memverifikasi bahwa pengguna adalah admin.
Firestore Rules perlu mengizinkan pengguna aplikasi membaca dokumen runtime;
penulisan dari klien tidak diperlukan.

```text
match /app_config/runtime {
  allow read: if request.auth != null;
  allow write: if false;
}
```

## Menambah config fitur

1. Tambahkan nilai baru ke enum `AppFeature` beserta `key`, `label`, dan
   `defaultEnabled`.
2. Tambahkan key yang sama ke `APP_FEATURE_KEYS` di Cloud Functions.
3. Tambahkan tile pengaturan di `AppConfigPage`.
4. Tentukan perilaku tiap role di `feature_access_policy.dart` bila berbeda dari
   pola yang sudah ada.

Setelah mengubah endpoint, deploy function:

```text
firebase deploy --only functions:setAppFeatureConfig
```
