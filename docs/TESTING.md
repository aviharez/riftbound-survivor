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

**Efek lebih kalem** (bloom diturunkan dan memakai mode "screen", jadi efek yang bertumpuk tidak lagi jadi layar putih):
- [ ] Late game dengan banyak proyektil (Tome of Multitude tinggi) tidak lagi silau / putih menutupi layar
- [ ] Efek tetap terasa "menyala", tidak jadi kusam
- [ ] Astral Blades maksimal 6 pedang (dulu bisa 11 dengan Multitude); jejaknya memendek kalau pedangnya banyak

**Final Swarm baru (gaya Megabonk)**:
- Tiap 1 menit naik **SWARM LV** (ada banner). Tiap level: musuh muncul lebih banyak, lebih cepat,
  HP dan damage-nya lebih besar, dan naiknya juga halus di dalam menit itu, jadi tidak pernah datar.
- Musuh baru **Wraith**: hantu biru bermata merah yang cepat dan **menembus tembok**. Porsinya naik tiap level.
- Di bawah timer ada **meter kesulitan** "Threat: Calm → ... → Doomed" yang naik seiring waktu,
  Cursed Tome / Avarice, dan swarm level.
- [ ] Final Swarm terasa makin sulit tiap menit sampai akhirnya kewalahan
- [ ] Wraith terlihat jelas dan terasa mengancam, tidak terlalu banyak di menit pertama
- [ ] Meter Threat terbaca dan tidak mengganggu
- [ ] Performa tetap oke saat swarm penuh (sekarang maks 300 musuh saat swarm)


**Weapon baru** (jenis serangan mengikuti dokumen *Riftbound Weapon Attack Design*, set prototipe 8 weapon):

| Weapon | Cara kerja |
| --- | --- |
| Arcane Bolt | bola sihir cyan ke musuh terdekat, memantul 1x |
| Flame Orb | bola api yang memantul antar musuh (2x, +1 di Lv 3/5/7) |
| Chain Lightning | petir melompat antar musuh |
| Meteor Fall | lingkaran merah muncul di bawah musuh, 0,5 dtk kemudian meteor jatuh |
| Astral Blades | pedang cahaya berputar mengelilingi karakter, meninggalkan jejak melingkar |
| Void Well | lubang hitam ungu menarik musuh ke tengah, lalu meledak |
| Frost Lance | tombak es menembus beberapa musuh dan memperlambat mereka |
| Thornseed | biji yang tumbuh jadi akar berduri saat kena: musuh di dalamnya kena damage dan melambat |

Frost Nova, Mana Burst, Spirit Blade dan orb api yang mengorbit sudah dihapus.

**Karakter** (pilih di akademi, baris atas):

| Karakter | Stat khusus | Weapon awal | Pasif per level |
| --- | --- | --- | --- |
| Astra (Mage) | HP 100, crit 5% | Arcane Bolt | +1% crit |
| Lyra (Fire Mage) | HP 85, damage 12, area +10%, cepat | Flame Orb | +2% damage |
| Kael (Knight) | HP 150, armor 10%, lambat | Astral Blades | +1% armor (maks 50%) |
| Nym (Healer) | HP 95, regen 0.6/dtk, luck 10, heal +50% | Thornseed | +0.12 HP/dtk regen |

- [ ] Tiap weapon terasa jelas jenis serangannya (pantul, tembus, area tertunda, tarik, orbit, akar)
- [ ] Astral Blades terlihat seperti pedang (gagang ungu, bilah cyan), bukan garis cahaya
- [ ] Jejak putaran pedang: sabetan cahaya berbentuk bulan sabit di belakang tiap pedang (putih-cyan di pedang, memudar ke ungu)
- [ ] Meteor: lingkaran peringatan terlihat sebelum meteor jatuh
- [ ] Semua weapon tetap menyerang sesuai attack speed walau tidak ada musuh
- [ ] Ada weapon/karakter yang jelas terlalu kuat atau terlalu lemah?

**Shrine**:
- [ ] Shrine yang belum dipakai memancarkan sinar lembut sesuai warnanya (terlihat dari dekat)
- [ ] Sinarnya hilang begitu shrine diambil (atau saat trial dimulai)

**VFX lain**:
- [ ] Musuh mati jadi kepulan asap kecil; elite mati meledak gelap; boss muncul dari portal dan mati dengan ledakan besar
- [ ] Rift Portal berputar ungu, level up, Moon Fountain (efek heal), dash (blink)
- [ ] Efek terasa "pixel art", tidak ada kotak/tepi terpotong di sekitar efek
- [ ] Performa saat banyak musuh dan efek sekaligus (Rift Surge, Final Swarm, banyak Void Well/meteor)

**Grafik**: Astra, Lyra, Kael, Nym, dan boss Corrupted Guardian memakai sprite PixelLab 8 arah (boss digambar 2x). Musuh dan chest memakai pixel art buatan Claude.
- [ ] Arah hadap karakter sesuai arah gerak
- [ ] Ukuran karakter (48 px) terasa pas, tidak terlalu besar dibanding musuh
- [ ] Boss terasa besar dan mengancam

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
