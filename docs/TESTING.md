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

**Tahap 4 selesai: waktu pembangunan + iklan berhadiah (placeholder).**
- Membangun / upgrade bangunan sekarang **butuh waktu nyata**. Biaya dibayar di awal, levelnya naik saat timer
  habis. Level 1 = 5 menit, Lv 2 = 30 menit, Lv 3 = 2 jam, Lv 4 = 8 jam. Bangunan karakter 30–60 menit.
  Sisa waktu di bawah 5 menit bisa langsung **FINISH** gratis.
- Hanya **1 tukang**: satu bangunan dibangun dalam satu waktu (tombol lain jadi BUILDER BUSY).
- Di peta, bangunan yang sedang dibangun pakai perancah kayu + gelembung timer. Saat sudah bisa diselesaikan,
  gelembungnya hijau "DONE!". Quest di kiri atas ikut menampilkan timernya.
- **Iklan berhadiah** (opsional, maks 10 per hari). Belum ada SDK iklan, jadi muncul layar "AD" 2 detik sebagai
  pengganti:
  - panel bangunan: tombol biru **AD -30m** (memotong 30 menit atau 25% sisa waktu, mana yang lebih besar);
  - Expedition: tombol **AD** di samping RECALL;
  - saat mati di Rift: **REVIVE (AD)** dengan 50% HP, sekali per run, atau GIVE UP;
  - layar hasil run: **x2 REWARDS (AD)** (resource dobel; equipment tidak).
- Belum ada: notifikasi Android saat timer selesai (butuh plugin, menyusul).
- [ ] Waktu bangun terasa wajar? Terlalu lama / terlalu cepat?
- [ ] Revive dan x2 rewards berjalan benar (cek gold di akademi bertambah dua kali)?
- [ ] Batas 10 iklan per hari terasa pas?

**UI revisi 2: font Galmuri, lebih berwarna, lebih sedikit teks, lebih besar.**
- Font diganti ke **Galmuri** (pilihan B): Galmuri 9 untuk teks, Galmuri 11 Bold untuk judul/tombol.
- Panel lebih terang (ungu dengan garis diagonal lebar), baris di dalam panel gelap, judul seksi berupa bar gelap
  dengan ikon, paku emas di sudut panel overlay. Tombol berwarna sesuai fungsi: emas = utama, hijau = aksi,
  merah = hapus/batal, biru = info.
- Teks dikurangi: stat, biaya, hadiah, slot, dan level sekarang berupa **ikon + angka**. Penjelasan panjang dipindah
  ke tooltip.
- Ornamen: peta akademi tetap terlihat (redup) di belakang halaman, gambar banner baru untuk Rift (Ruined
  Courtyard) dan Expedition, karakter besar di halaman Characters/Rift.
- Halaman yang diubah: Characters (stat ikon, Enhance/Equipment/Bond pakai slot ikon), Rift (banner, hadiah ikon,
  kit karakter), Expedition (kartu misi + ikon hadiah, timer bar, CLAIM/RECALL), Codex (grid ikon, resep evolusi
  bergambar), panel bangunan (biaya dalam slot ikon), Lessons (kartu 2 kolom), Workshop (tas berupa grid item),
  Dormitory (kartu penghuni), menu pause dan layar hasil run (ikon stat, build, hadiah).
- Kartu level up tetap (sudah oke), cuma fontnya ikut Galmuri.
- [ ] Font Galmuri terbaca jelas di HP?
- [ ] Masih terasa terlalu banyak teks? Halaman mana?
- [ ] Warna sudah tidak monoton?
- [ ] Tombol cukup besar untuk jempol?

**Sebelumnya: tahap 3: layar utama = peta akademi.**
- Layar utama sekarang **peta akademi** yang bisa digeser. Bangunan dibuat dengan PixelLab; yang masih runtuh
  tampil sebagai reruntuhan + hologram cyan bangunannya. Panah hijau = bisa dibangun / di-upgrade sekarang.
- **Ketuk bangunan** → panel bangunan: status, efek level berikutnya, kebutuhan resource (punya / perlu),
  tombol BUILD / UPGRADE, plus tombol aksi (Lessons, Craft, Rooms, Meet).
- Kiri atas: karakter yang dipilih + Academy Lv; di bawahnya **Quests** (tujuan yang sedang berjalan; quest
  dengan hadiah datang di tahap lokasi). Kanan atas: resource + tombol **Settings** (Reset save pindah ke sini).
- Kiri bawah: **Characters / Expedition / Codex** (halaman penuh dengan tombol kembali). Kanan bawah: tombol
  besar **ENTER THE RIFT** → halaman Rift → START.
- [ ] Peta enak digeser di HP, ketuk bangunan tidak terpicu saat menggeser
- [ ] Tampilan sudah terasa seperti game jualan? Apa yang masih kurang?
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
