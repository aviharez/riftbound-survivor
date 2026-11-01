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

**UI pixel ala Overgeared Hero + kartu level up baru.**
- Seluruh UI (layar utama, semua halaman, panel, HUD saat run) diganti ke gaya pixel: panel ungu gelap bergaris
  diagonal, garis tepi hitam tegas, bevel ungu, judul pita merah, tombol X merah berbentuk wajik, tombol utama
  berbingkai emas, tombol hijau untuk aksi. Posisi menu tetap seperti layout HoK.
- 64 ikon pixel baru (resource, menu, semua senjata, semua tome, stat) dibuat dengan PixelLab.
- Font pixel: DotGothic16 (teks) + Silkscreen (judul/tombol). Ukuran font dikunci ke grid pixel supaya tajam.
- **Level up**: tidak ada lagi panel besar dengan 3 tombol lebar. Sekarang 3 kartu ringkas: jenis (WEAPON/TOME),
  level (NEW atau LV 2>3), ikon besar, nama, efek, petunjuk combo (emas), strip rarity di bawah. Shrine Ley
  memakai kartu yang sama (BOON).
- Slot senjata/tome di kiri atas saat run sekarang berupa ikon + angka level (gembok untuk slot terkunci).
- [ ] Teks terbaca jelas di HP (tidak terlalu kecil / buram)?
- [ ] Kartu level up enak dibaca dan dipilih dengan jempol?
- [ ] Ikon-ikonnya cocok dengan senjata/tome-nya? Ada yang mirip game lain?
- [ ] Ada layar yang masih terasa kosong atau terlalu penuh?

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
