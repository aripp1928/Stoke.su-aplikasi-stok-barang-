# SETOKE.SU

Aplikasi stok kedai kopi (Flutter + Supabase) — target **Android 13 (API 33)**.

## Struktur singkat
- 4 tab: **Beranda · Barang · Jual · Laporan**
- Beranda: ringkasan stok, aksi cepat (Restok / Pakai / Jual / Riwayat), peringatan stok, aktivitas terakhir
- Barang: daftar barang, resep, supplier (form lewat bottom sheet)
- Riwayat stok: satu daftar dengan filter Semua / Masuk / Keluar (dibuka dari Beranda)

## Menjalankan
```
flutter pub get
flutter run
```
Android: `minSdk = 33`, `targetSdk = 33` (lihat `android/app/build.gradle.kts`).
