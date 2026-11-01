# Checklist playtest

Mainkan 2–3 run, lalu laporkan apa saja yang terasa salah. Sertakan **seed** (ada di menu pause dan layar hasil) supaya map-nya bisa diulang persis.

## Cara lapor
Buat GitHub Issue atau tulis di chat dengan format:
- Seed:
- Perangkat: (PC / nama HP)
- Yang terjadi:
- Yang seharusnya:
- Menit ke berapa:

## Cara memasang build terbaru di HP
Buka https://github.com/aviharez/riftbound-survivor/releases/tag/latest-build dari browser HP,
unduh `riftbound-debug.apk`, lalu pasang (izinkan "install unknown apps" untuk browser).
Build baru terpasang di atas build lama dan save akademi tetap ada.

## Yang baru di build ini (fokus tes)

**Tahap 3: tampilan baru (reskin UI) + navigation bar.**
- Seluruh akademi memakai tampilan baru sesuai referensi: panel navy dengan bingkai emas berornamen, glow cyan,
  font judul Cinzel dan font isi Nunito, latar langit malam dengan nebula Rift yang bergerak pelan.
- **Navigation bar** di bawah dengan 5 halaman:
  - **Academy**: semua bangunan sebagai kartu (Restore / Upgrade, plus tombol Lessons / Craft / Rooms / Meet).
  - **Characters**: deretan roster di atas; kartu karakter (level, EXP, stat total termasuk level + equipment +
    bond, tombol "Select for Rift"); tab Enhance / Equipment / Bond; potret besar (sprite animasi diam,
    nanti diganti ilustrasi anime-mu).
  - **Rift**: persiapan run (lokasi, karakter + loadout, bantuan akademi, rekor) dan tombol besar ENTER THE RIFT.
  - **Expedition**: pilih misi di kiri, pilih karakter di kanan, START EXPEDITION; yang sedang pergi tampil
    dengan timer (Collect / Recall).
  - **Codex**: arsip karakter (yang terkunci tampil ???), senjata + pasangan evolusinya, bestiary musuh;
    tombol Reset save pindah ke sini.
- Di dalam run: panel level up, pause dan layar hasil juga memakai gaya baru.
- **Ilustrasi besar**: spesifikasinya ada di `assets/illustrations/README.md` (PNG transparan 768x1024,
  menghadap sedikit ke kiri, baju sama dengan sprite). Taruh file `<id>.png` di folder itu dan game otomatis
  memakainya di halaman Characters.
- [ ] Semua halaman enak dibaca di layar HP (teks tidak terlalu kecil / terpotong)
- [ ] Navigation bar dan tombol mudah diketuk
- [ ] Alur: pilih karakter di Characters → Rift → ENTER THE RIFT → hasil → kembali ke akademi
- [ ] Ekspedisi dari halaman Expedition (kirim, tunggu, Collect)
- [ ] Kesan tampilan dibanding referensi: warna, bingkai, font — apa yang kurang?
- [ ] Semua fitur tahap 2 (enhance, equipment, craft, bond, dorm, ekspedisi) masih jalan di tampilan baru

**Sebelumnya: tahap 2 (sistem meta) — checklist lama tetap berlaku.**

**Sebelumnya: tahap 1 (13 karakter, sprite + animasi).**
- [ ] Animasi jalan & diam (beberapa arah masih perlu revisi, dicatat untuk nanti)

## Yang perlu dicek di build sekarang

**Kontrol**
- [ ] Joystick di separuh kiri layar terasa responsif
- [ ] Tombol DASH mudah ditekan dan tidak salah sentuh
- [ ] Teks dan tombol terbaca di layar HP

**Map & eksplorasi**
- [ ] Spawn player dan posisi portal terasa berbeda tiap run
- [ ] Minimap dan peta penuh (tombol MAP) jelas menunjukkan area yang sudah dilewati
- [ ] Mencari portal tidak terlalu lama atau terlalu cepat
- [ ] Tidak ada area, chest, atau shrine yang tidak bisa dicapai

**Chest & shrine**
- [ ] Harga chest masuk akal (25, 35, 49, …)
- [ ] Kelima shrine bekerja: Ley (pilih boon), Trial (kalahkan musuh dalam 45 dtk), Avarice (gold + run lebih sulit), Aether Well (tarik XP), Moon Fountain (heal)

**Tempo run**
- [ ] Menit 0–2 tidak terlalu sulit / terlalu membosankan
- [ ] Rift Surge (07:30, 05:00, 02:30) terasa sebagai momen tegang
- [ ] Elite cukup kuat tapi bisa dikalahkan
- [ ] Boss bisa dibaca polanya (tembakan cincin, dash bergaris merah, panggil slime)
- [ ] Final Swarm terasa seperti "harus segera pergi"

**Performa (HP)**
- [ ] Tidak patah-patah saat banyak musuh (Rift Surge, Final Swarm)
- [ ] HP tidak cepat panas
