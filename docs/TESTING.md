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

**Karakter** (pilih di akademi, baris atas):

| Karakter | Stat khusus | Weapon awal | Pasif per level |
| --- | --- | --- | --- |
| Astra (Mage) | HP 100, crit 5% | Arcane Bolt | +1% crit |
| Lyra (Fire Mage) | HP 85, damage 12, area +10%, cepat | Flame Orb | +2% damage |
| Kael (Knight) | HP 150, armor 10%, lambat | Spirit Blade | +1% armor (maks 50%) |
| Nym (Healer) | HP 95, regen 0.6/dtk, luck 10, heal +50% | Frost Nova | +0.12 HP/dtk regen |

- [ ] Tiap karakter terasa berbeda cara mainnya
- [ ] Ada karakter yang jelas terlalu kuat atau terlalu lemah?

**VFX** (efek pixel art pixelfx; Frost Nova dan Arcane Bolt dibuat khusus untuk sudut pandang top-down):
- [ ] Semua weapon menyerang terus sesuai attack speed, juga saat tidak ada musuh (Arcane Bolt ke arah hadap,
      Mana Burst di depan karakter, Storm Chain zap ke depan)
- [ ] Arcane Bolt: trail lurus di belakang kepala proyektil, ke segala arah
- [ ] Frost Nova: cincin es di lantai di sekeliling karakter, kristal muncul melingkar
- [ ] Spirit Blade: sekarang tebasan putar 360° (elips di lantai), mengenai semua arah
- [ ] Flame Orb (Lyra): komet api yang mengorbit, ekornya mengikuti lintasan
- [ ] Mana Burst dan Storm Chain masih terasa cocok untuk tampilan dari atas?
- [ ] Musuh mati jadi kepulan asap kecil; elite mati meledak gelap; boss muncul dari portal dan mati dengan ledakan besar
- [ ] Rift Portal berputar ungu, level up, Moon Fountain (efek heal), dash (blink)
- [ ] Shrine yang diaktifkan memberi sinar kecil sederhana sesuai warna shrine; chest tidak lagi meninggalkan efek
- [ ] Efek terasa "pixel art", tidak ada kotak/tepi terpotong di sekitar efek
- [ ] Performa saat banyak musuh mati sekaligus (Rift Surge, Final Swarm)

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
