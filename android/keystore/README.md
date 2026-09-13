# Keystore rilis / upload key (TIDAK dikomit)

Folder ini menampung `upload-keystore.jks` — keystore yang menandatangani
build **release**/AAB untuk Play Store (beda dengan `debug.keystore` di
`android/app/keystore/`, yang cuma untuk build debug/testing). File
keystore-nya sendiri tetap di-*gitignore* (root `.gitignore`:
`/android/keystore/`), jadi tidak pernah masuk riwayat git repo ini.

`android/key.properties` (juga di-gitignore) menunjuk ke keystore ini —
lihat `android/app/build.gradle.kts`, bagian `signingConfigs["release"]`.

## Kalau mau build AAB lokal

Buat `android/key.properties` (isi manual, TIDAK dikomit):

```
storePassword=<password keystore>
keyPassword=<password keystore>
keyAlias=upload
storeFile=../keystore/upload-keystore.jks
```

Lalu `flutter build appbundle --release`.

## Kalau mau build AAB otomatis lewat CI (`release-build.yml`)

Workflow `.github/workflows/release-build.yml` (trigger manual lewat tab
Actions, BUKAN otomatis tiap push — rilis ke Play Store harus disengaja)
membuat ulang `upload-keystore.jks` dan `key.properties` dari GitHub
Secrets saat run, lalu build AAB dan upload otomatis ke Play Console lewat
Google Play Developer API. Secret yang dibutuhkan:

- `UPLOAD_KEYSTORE_BASE64` — isi base64 dari file `upload-keystore.jks`
- `UPLOAD_KEYSTORE_PASSWORD` — password keystore (dipakai sebagai
  storePassword & keyPassword sekaligus)
- `UPLOAD_KEY_ALIAS` — alias key di dalam keystore (mis. `upload`)
- `PLAY_SERVICE_ACCOUNT_JSON` — isi file JSON service account Google Cloud
  yang sudah diberi izin rilis di Play Console (Users and permissions)

**PENTING — jangan pernah ganti/generate ulang keystore rilis begitu saja**
kalau yang lama masih valid. Google Play mengunci "upload key certificate"
per app: kalau keystore hilang/gantinya sembarangan, update berikutnya bisa
ditolak Play Console kecuali lewat proses resmi "Request upload key reset"
(Play Console → app → Protected with Play → Play Store protection →
Protect app signing key → Manage Play app signing).
