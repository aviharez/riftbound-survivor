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

**Akademi fase 1: karakter murid & guru.**
- Semua karakter punya **pasif mekanik** baru (lihat detail di akademi saat memilih karakter):
  - Astra: crit memercik ke 1 musuh terdekat (50% damage)
  - Lyra: musuh yang dibunuh 25% meledak api
  - Kael: saat terkena serangan, gelombang pedang menebas musuh di sekitar
  - Nym: musuh yang mati saat terjerat akar menyembuhkanmu
  - Selene (baru): musuh yang melambat/beku menerima +25% damage
  - Noah (baru): musuh beracun yang mati bisa menyebarkan awan racun kecil
- **Bangunan baru** (baris bangunan bisa digeser ke samping):
  - **Staff Room**: guru memberi **Lessons** = upgrade permanen (damage, HP, attack speed, speed, luck, XP, gold,
    pickup). Dibeli pakai EXP + gold, rank maks 3 per level Staff Room (6 di level 2).
  - **Frost Tower**: membuka **Selene** (Cryomancy, Frost Lance).
  - **Alchemy Lab**: membuka **Noah** (Alchemy, Venom Bloom).
- Karakter terkunci tampil abu-abu; diketuk = muncul cara membukanya. Baris karakter juga bisa digeser.
- Selene & Noah sekarang punya sprite PixelLab 8 arah (dibuat Claude).
- Save lama otomatis dimigrasi (tidak hilang).
- [ ] Save lama tetap ada setelah update (gold, bangunan, karakter)
- [ ] Baris karakter & bangunan enak digeser di HP, tombol ENTER THE RIFT tetap terlihat
- [ ] Panel Lessons terbaca, beli lesson terasa berpengaruh di run
- [ ] Pasif tiap karakter terasa (terutama Kael saat terkena serangan, Lyra saat membunuh)
- [ ] Harga bangunan & lesson masuk akal (terlalu mahal / murah?)

**Info combo di kartu level-up (permintaanmu):** kartu tampil biasa selama kamu belum punya pasangannya. Kalau sudah
punya weapon-nya lalu tome pasangannya muncul sebagai NEW, kartunya menulis
"COMBO + Flame Orb (owned) -> Solar Cataclysm at Lv 8". Begitu juga sebaliknya: sudah punya tome-nya, lalu kartu
weapon pasangannya muncul (baru atau naik level). Teks lama "Evolves at Lv 8 with ..." yang selalu tampil sudah dihapus.
- [ ] Info combo muncul hanya saat pasangannya sudah dimiliki
- [ ] Teks kartu terbaca dan tidak terpotong di layar HP

**Perbaikan dari masukanmu (1 Nov):**
- **Arcane Bolt vs Flame Orb** sekarang beda cara kerjanya. Bolt: cepat, kecil, **homing** (jalurnya melengkung
  mengejar musuh, ada jejak cyan). Flame: besar & lambat, **memantul dari dinding juga**, dan tiap kena meledak jadi
  semburan api berbentuk bintang yang melukai musuh di sekitarnya.
- **Meteor**: sekarang batu abu-abu gelap berasap dengan retakan menyala, bayangannya di lantai membesar saat jatuh,
  lalu benturan berupa cincin debu, pecahan batu yang memantul, dan kawah yang mendingin.
- **Astral Blades**: glow dikurangi. Bentuk jejak bulan sabit tetap, tapi tidak lagi berpendar tebal; hanya tepi tipisnya yang bercahaya.
- **Void Well**: ledakan sekarang tepat di pusat sedotan (sebelumnya bergeser ±40 px ke atas karena titik jangkar efeknya beda).
- **Thornseed**: efek baru: area jeratan bergaris hijau di lantai, sulur berduri merambat keluar, duri mencuat, lalu
  layu saat habis. Musuh yang sedang terjerat berwarna **kehijauan**.
- [ ] Bolt dan Flame terasa beda jelas
- [ ] Meteor terlihat seperti batu jatuh, bukan bola api
- [ ] Glow Astral Blades pas (tidak tebal, jejak masih kelihatan)
- [ ] Ledakan Void Well di tengah pusaran
- [ ] Cara kerja Thornseed jelas: kelihatan area jeratnya & musuh yang terjerat


**Evolusi weapon**. Aturannya: weapon **Lv 8 (maks)** + punya **tome pasangannya** (Lv berapa saja).
Begitu syarat terpenuhi muncul banner "... can evolve — open a chest!". **Chest berikutnya** (berbayar atau emas)
memberi evolusi, bukan item. Evolusi menggantikan weapon aslinya di slot yang sama, dan di HUD slotnya
berbingkai emas dengan huruf **E**. Kartu level-up weapon menulis "Evolves at Lv 8 with Tome of ...".

| Weapon | Tome | Evolusi | Yang harus terlihat |
| --- | --- | --- | --- |
| Arcane Bolt | Multitude | Prismatic Barrage | kipas 6 bolt beda elemen (cyan, api, es, daun); api memercik, es & daun memperlambat |
| Flame Orb | Ricochet | Solar Cataclysm | matahari kecil memantul, lalu meledak: cincin api di lantai + jari-jari api |
| Chain Lightning | Haste | Thunderstorm Network | 3 petir dari atas sekaligus, rantainya menyebar ke seluruh gerombolan |
| Meteor Fall | Expanse | Starfall | 8 meteor jatuh beruntun satu per satu |
| Astral Blades | Vitality | Blade Halo | 6 pedang berputar, sesekali satu pedang dilempar menembus musuh |
| Void Well | Attraction | Event Horizon | lubang hitam jauh lebih besar & kuat, runtuh dengan cincin ungu |
| Frost Lance | Precision | Absolute Zero | tombak es, di ujungnya kristal es mencuat & musuh **membeku** (biru, diam, tidak melukai) |
| Thornseed | Mending | Worldroot Bloom | akar besar yang menyebar ke 2 akar kecil dan menjerat (membekukan sebentar) musuh |

Boss tidak bisa dibekukan, hanya diperlambat. Semua efek ledakan baru dibuat khusus untuk sudut kamera top-down.

- [ ] Banner "can evolve" muncul saat syarat terpenuhi, lalu chest berikutnya memberi evolusi (banner EVOLUTION!)
- [ ] **Penting:** apakah Lv 8 cukup sering tercapai di run biasa? Kalau jarang, bilang saja, syaratnya bisa diturunkan ke Lv 6
- [ ] Tiap evolusi terasa jelas lebih kuat dan berbeda dari weapon aslinya
- [ ] Efek ledakan (Solar, Absolute Zero, Event Horizon) terbaca top-down, cincin "rebah" di lantai
- [ ] Tidak ada yang menyilaukan: Event Horizon dan 6 pedang Blade Halo terutama
- [ ] Musuh beku terlihat jelas (biru) dan tidak bisa melukai selama beku
- [ ] Performa oke saat evolusi + Final Swarm

**6 weapon baru** (muncul di kartu level-up seperti weapon lain; jenis serangan yang belum ada sebelumnya):

| Weapon | Jenis | Cara kerja |
| --- | --- | --- |
| Crescent Slash | tebasan menembus | bulan sabit cahaya terbang lurus, membesar, menembus semua musuh |
| Rune Chakram | keluar lalu kembali | cakram emas berputar terbang keluar, lalu balik ke kamu; kena musuh di dua arah |
| Arcane Familiar | summon | kristal kecil bermata melayang mengitarimu dan menembak sendiri (+1 di Lv 4/7) |
| Aether Beam | sinar | sinar lurus instan menembus satu barisan musuh (sinar ke-2 di Lv 5) |
| Venom Bloom | racun | awan racun hijau dilempar ke musuh, damage terus selama 3 dtk |
| Arcane Mine | jebakan | rune di lantai di sekitarmu; meledak saat musuh mendekat (maks 8 rune) |

- [ ] Tiap weapon terasa beda jenis serangannya
- [ ] VFX terbaca top-down (rune & noda racun rebah di lantai, familiar melayang di atas bayangannya)
- [ ] Familiar terlihat sebagai makhluk kecil yang lucu, tidak tertutup karaktermu
- [ ] Aether Beam tidak menyilaukan
- [ ] Awan racun cukup terlihat di atas rumput hijau
- [ ] Ada weapon baru yang jelas terlalu kuat/lemah?

**Dari build sebelumnya (masih perlu dicek kalau belum):** Final Swarm per menit (SWARM LV, Wraith, meter Threat),
jejak Astral Blades.

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
