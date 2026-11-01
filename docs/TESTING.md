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

**Tahap 3 (revisi): layar utama = peta akademi.**
- Layar utama sekarang **peta akademi** yang bisa digeser. Bangunan dibuat dengan PixelLab; yang masih runtuh
  tampil sebagai reruntuhan + hologram cyan bangunannya. Panah hijau = bisa dibangun / di-upgrade sekarang.
- **Ketuk bangunan** → panel bangunan: status, efek level berikutnya, kebutuhan resource (punya / perlu),
  tombol BUILD / UPGRADE, plus tombol aksi (Lessons, Craft, Rooms, Meet).
- Kiri atas: karakter yang dipilih + Academy Lv; di bawahnya **Quests** (tujuan yang sedang berjalan; quest
  dengan hadiah datang di tahap lokasi). Kanan atas: resource + tombol **Settings** (Reset save pindah ke sini).
- Kiri bawah: **Characters / Expedition / Codex** (halaman penuh dengan tombol kembali). Kanan bawah: tombol
  besar **ENTER THE RIFT** → halaman Rift → START.
- Gaya UI baru: panel kaca navy transparan, tombol emas miring, font Nunito + Exo 2 Italic (Cinzel dibuang).
- [ ] Peta enak digeser di HP, ketuk bangunan tidak terpicu saat menggeser
- [ ] Tampilan sudah terasa seperti game jualan? Apa yang masih kurang?
- [ ] Font baru oke?
- [ ] Posisi bangunan / jalan di peta (mau diatur ulang?)

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
