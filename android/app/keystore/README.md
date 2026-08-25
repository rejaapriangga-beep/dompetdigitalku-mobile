# Keystore debug (TIDAK dikomit — dibuat dari GitHub secret saat build)

Folder ini menampung `debug.keystore` saat build (dibuat otomatis oleh
workflow `.github/workflows/android-build.yml` dari secret repo
`DEBUG_KEYSTORE_BASE64`) — filenya sendiri tetap di-*gitignore*
(`android/.gitignore`: `**/*.keystore`), jadi tidak pernah masuk riwayat
git repo publik ini.

**Kenapa perlu keystore debug yang stabil, bukan yang auto-generate seperti
biasa?** Setiap run GitHub Actions jalan di VM baru yang bersih. Kalau
dibiarkan default, Android Gradle Plugin auto-membuat
`~/.android/debug.keystore` baru dengan kunci ACAK tiap run — akibatnya:

- `adb install -r` gagal (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) tiap kali
  update ke APK dari build CI yang berbeda dari sebelumnya.
- SHA-1 fingerprint ikut berubah tiap build, jadi Login Google (yang
  didaftarkan lewat SHA-1 di Google Cloud Console) tidak akan pernah
  konsisten (selalu `DEVELOPER_ERROR`).

Dengan keystore debug yang TETAP (disimpan sekali sebagai secret, dipakai
ulang di semua run), APK dari build manapun selalu bisa saling
update/replace, dan SHA-1-nya bisa didaftarkan SEKALI ke Google Cloud
Console untuk fix Login Google.

**JANGAN** pernah pakai keystore ini untuk build `release`/rilis ke Play
Store — untuk itu tetap pakai `key.properties` + keystore rilis terpisah
(lihat `android/app/build.gradle.kts`, bagian `signingConfigs["release"]`).

SHA-1 keystore debug ini (daftarkan ke Google Cloud Console untuk fix Login
Google): `90:98:27:7E:7C:6D:AE:DC:E4:99:9F:3B:2A:C9:4D:F9:2B:52:02:9C`

## Kalau mau build lokal (opsional)

Build lokal tidak akan punya file ini secara otomatis (cuma dibuat oleh
workflow CI dari secret). Kalau suatu saat build lokal dibutuhkan, salin
isi secret `DEBUG_KEYSTORE_BASE64` dari GitHub, lalu:

```
echo "<isi secretnya>" | base64 -d > android/app/keystore/debug.keystore
```
