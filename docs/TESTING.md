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

**Tahap 1: art karakter (13 karakter, sprite baru + animasi jalan & diam).**
- Semua 13 karakter memakai sprite PixelLab v3 baru (Astra, Lyra, Kael, Nym dibuat ulang; Selene & Noah
  tetap desain yang sama). Semua punya **animasi jalan** (6 frame) dan **animasi diam/bernapas** (4 frame) di 8 arah.
- **7 karakter baru** yang bisa dimainkan, dibuka dengan memulihkan bangunan:
  - Raika (Bell Tower, Chain Lightning): tiap 8 kill melepas petir yang melompat ke 4 musuh
  - Sera (Duel Hall, Crescent Slash): elite & boss menerima +30% damage
  - Celeste (Observatory, Meteor Fall): tiap 5 detik bintang jatuh ke musuh di dekatmu
  - Runa (Rune Workshop, Rune Chakram): musuh yang mati kadang meninggalkan rune yang meledak saat diinjak musuh
  - Lumi (Arcana Lab, Aether Beam): kelebihan damage saat membunuh pindah ke musuh terdekat
  - Vesper (Forbidden Archive, Void Well): musuh yang mati kadang runtuh, menarik & melukai musuh di sekitarnya
  - Wren (Library sampai level maks, Arcane Familiar): pelindung kertas menahan 1 serangan tiap 6 detik
- Bangunan baru ini sementara masih model lama (bayar langsung, tanpa timer); sistem konstruksi ber-timer
  datang di tahap 4.
- [ ] Animasi jalan terlihat mulus di 8 arah (tidak ada frame yang "kedip"/berubah baju)
- [ ] Animasi diam terlihat saat berhenti
- [ ] Ukuran & posisi kaki karakter pas di bayangan
- [ ] Ada karakter yang desainnya terasa mirip karakter game/anime terkenal? (laporkan)
- [ ] Pasif karakter baru terasa (coba buka beberapa lewat bangunan)
- [ ] Baris karakter (13) tetap enak digeser di HP

**Sebelumnya: akademi fase 1 (Staff Room, Frost Tower, Alchemy Lab, pasif mekanik).**
- [ ] Save lama tetap ada setelah update (gold, bangunan, karakter)
- [ ] Panel Lessons terbaca, beli lesson terasa berpengaruh di run

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
