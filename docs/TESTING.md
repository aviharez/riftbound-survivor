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

**Tahap 2: sistem meta (level karakter, enhance, equipment, crafting, bond, dorm, ekspedisi).**
Save lama otomatis dimigrasi. Tombol baru di akademi: **"Level · Enhance / Equipment · Bond"** (di samping
detail karakter), kartu bangunan **Workshop** (tombol Craft) dan **Dormitory** (tombol Open).
- **Level karakter** (maks 30): EXP karakter didapat dari run yang dimainkan dengan karakter itu (jumlahnya
  sama dengan EXP akademi). Tiap level: +4 HP, +2% damage. Layar hasil run menampilkan level & level up.
- **Enhance** (2 jalur per karakter, maks rank 5, rank N butuh karakter Lv 5×N), bayar gold + **Arcane Shards**:
  - Passive: trait karakter +15% lebih kuat per rank
  - Signature weapon: senjata awal (dan evolusinya) +8% damage, +4% attack speed per rank
  - Arcane Shards: boss memberi 3, tiap 3 elite memberi 1 (tetap didapat walau kalah)
- **Equipment**: 3 slot (Weapon / Armour / Accessory), inventori bersama (maks 60), 5 rarity
  (Common–Legendary). Drop dari boss, kemenangan, dan elite (15%). Karakter mana pun bisa memakai item apa pun.
- **Workshop** (bangunan baru, 3 level): craft item dari Materials + **Courtyard Essence** (essence didapat
  dari run: 1 per 40 kill, boss +5). Lv 1 sampai Uncommon, Lv 2 Rare, Lv 3 Epic; Legendary hanya dari drop.
  Salvage = 40% biaya kembali (ketuk 2x).
- **Bond** (maks Lv 5): dari run (+12, menang +8), ekspedisi (+20), ngobrol harian di Dorm (+15).
  Tiap level: +1% damage, +3 HP, dan membuka **1 cerita pendek** (65 cerita total, bahasa Inggris,
  ditulis Claude — tolong direview, filenya `scripts/data/bond_scenes.gd`).
- **Dormitory** (bangunan baru, 3 level): kamar (4 / 8 / 13) untuk karakter yang bisa diajak ngobrol sekali
  sehari; slot ekspedisi = level Dormitory.
- **Ekspedisi** (waktu nyata, jalan walau game ditutup): 1 jam / 2 jam / 4 jam / 8 jam, hadiah gold, materials,
  essence, shards, equipment; makin tinggi level karakter makin besar hadiahnya. Karakter yang sedang
  ekspedisi tidak bisa dipilih untuk Rift, dan karakter Rift tidak bisa dikirim. Recall = pulang tanpa hadiah.
- Angka-angka ini tebakan awal; bilang kalau terasa terlalu lambat / cepat.
- [ ] Save lama tetap aman setelah update
- [ ] Level & level up karakter terlihat di layar hasil run dan di panel karakter
- [ ] Enhance bisa dibeli saat level cukup, efeknya terasa di run
- [ ] Item drop muncul di layar hasil, bisa dipakai / dilepas / dipindah ke karakter lain
- [ ] Craft & salvage di Workshop jalan, essence terhitung benar
- [ ] Ngobrol di Dorm hanya sekali sehari, cerita bond terbuka saat level bond naik
- [ ] Ekspedisi: tutup game, buka lagi setelah waktunya habis, hadiah bisa diambil
- [ ] Panel-panel terbaca di layar HP (teks tidak terpotong)
- [ ] Cerita bond: ada yang terasa aneh / tidak cocok dengan karakternya?

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
