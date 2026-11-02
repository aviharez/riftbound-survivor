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

**Mirror Gate diganti Holy Nova.**
- Tiap ~3,6 detik gelombang cahaya emas melebar dari karakter (cincin datar di lantai), memukul semua musuh yang
  dilewatinya dan mendorong mereka mundur. Boss kena damage tapi tidak terdorong. Mulai Lv 5 ada gelombang kedua.
- [ ] Impact-nya terasa? Dorongannya terlalu jauh / kurang? Cahayanya terlalu silau?

**Animasi musuh, boss, dan familiar (baru).**
- Semua 21 musuh sekarang beranimasi (9 frame PixelLab): slime memantul, kelelawar/ngengat mengepak,
  golem/armor berjalan, api wisp berkedip, dll. Musuh Courtyard (slime, bat, brute, caster, wraith) digambar
  ulang dengan PixelLab supaya gayanya sama dengan musuh lokasi lain.
- Kelima boss sekarang punya animasi jalan 8 arah dan pose serang (mengangkat tangan / melempar) setiap kali
  menembak cincin, spiral, volley, blink, atau memanggil minion. Saat bersiap menyeruduk, boss menahan pose
  ancang-ancang; saat menyeruduk, langkahnya lebih cepat.
- Arcane Familiar sekarang makhluk kristal kecil bersayap (PixelLab) dengan animasi melayang dan animasi
  menembak (mengisi tenaga lalu menembakkan bola cahaya).
- [ ] Gerakan musuh enak dilihat? Ada yang terlalu cepat / lambat / patah-patah? Sebutkan nama musuhnya.
- [ ] Boss: jalannya cocok? Pose serangnya terlihat?
- [ ] Familiar: lucu? Terlihat jelas waktu menembak?
- [ ] Musuh yang dibekukan (Glacial Burst / Absolute Zero) berhenti bergerak?

**Audio (tahap 6): suara dan musik pertama.**
- Semua suara dibuat dengan kode (sintesis, tanpa rekaman): pukulan, kritikal, musuh mati, gem, koin, level up,
  chest, shrine, evolusi, ledakan, petir, es, dash, terluka, boss mengaum, portal, menang/kalah, klik tombol,
  bangunan selesai, klaim quest.
- 3 musik loop: **akademi** (tenang), **Rift** (cepat), **boss / Final Swarm** (lebih tegang).
- Settings: tombol **MUSIC** dan **SOUND EFFECTS** ON/OFF (tersimpan, tidak ikut terhapus saat reset save).
- Aku tidak bisa mendengar hasilnya, jadi tolong nilai: mana yang mengganggu, terlalu keras, terlalu pelan,
  atau tidak cocok. Semua bisa diubah lewat angka di skripnya.
- [ ] Musik akademi / Rift / boss enak didengar? Terlalu berulang?
- [ ] Suara pukulan & musuh mati tidak berisik saat ramai?

**Revisi animasi:** jalan Wren arah timur & tenggara (bukunya tidak hilang lagi) dan jalan Kael arah timur
(pedangnya tidak hilang lagi). Kalau ada arah lain yang menurutmu masih aneh, sebutkan karakter + arahnya.

**Evolusi senjata alpha + 8 senjata baru.**
- 6 evolusi baru (senjata Lv 8 + tome-nya, lalu buka chest):
  - Crescent Slash + Tome of Power = **Lunar Cross**: dua bulan sabit besar bersilangan.
  - Rune Chakram + Tome of Swiftness = **Infinity Loop**: 6 cakram ke segala arah lalu kembali.
  - Arcane Familiar + Tome of Study = **Familiar Legion**: 5 familiar (ada yang menembak kipas, ada yang tembus).
  - Aether Beam + Tome of Fortune = **Celestial Ray**: sinar lebar yang meninggalkan jejak emas yang membakar.
  - Venom Bloom + Cursed Tome = **Plague Garden**: musuh yang mati di dalam awan menyebarkan awan baru.
  - Arcane Mine + Tome of Greed = **Runic Chain**: satu rune meledak memicu rune lain di dekatnya.
- 8 senjata baru (muncul di level up):
  - **Hex Mark**: menandai musuh terkuat, yang ditandai menerima damage lebih besar.
  - **Glacial Burst**: ledakan es di sekitarmu; mulai Lv 5 bisa membekukan.
  - **Riftstorm**: petir ungu menyambar musuh acak setelah lingkaran peringatan.
  - **Phantom Knight**: ksatria hantu menyerbu menembus satu barisan musuh.
  - **Prism Sweep**: sinar pelangi menyapu satu lingkaran penuh di sekitarmu.
  - **Gravity Lens**: lensa di atas kerumunan; tembakanmu dibelokkan ke musuh, musuh di dalamnya kena damage lebih.
  - **Holy Nova** (menggantikan Mirror Gate): gelombang cahaya emas melebar dari pemain, memukul dan mendorong musuh.
  - **Crystal Barricade**: dinding kristal yang mendorong musuh, menahan peluru musuh, dan memantulkan tembakanmu.
- [ ] Senjata mana yang terasa paling seru / paling lemah?
- [ ] Efeknya terbaca top-down?

**Tahap 5f: quest dengan hadiah.**
- Panel QUESTS di layar utama sekarang berisi: pemberitahuan (ekspedisi pulang, bangunan selesai), **1 quest
  cerita** (kuning, berurutan: main run pertama, pulihkan Library, menangkan Courtyard, dst.) dan **3 quest harian**
  (ganti setiap hari: kalahkan 400 monster, buka 12 chest, menang 1 run, ngobrol di asrama, dll.).
- Angka di kanan = progres. Saat selesai muncul tombol hijau **CLAIM** → hadiah langsung masuk.
- Ketuk teks quest untuk langsung ke tempatnya (halaman Rift, bangunan, asrama, dll.).
- [ ] Hadiah quest terasa pas? Quest harian terlalu mudah / susah?

**Tahap 5b–5e: empat lokasi baru dengan musuh, boss, dan warna peta sendiri.**
- **Whispering Forest:** Angry Sprout, Dusk Moth, Bramble Brute (menyeruduk setelah ancang-ancang garis merah),
  Forest Wisp (3 api sekaligus). Boss **Thornmother**.
- **Forgotten Library:** Inkblot (pecah jadi 2 tetes saat mati), Quill Owl, Hollow Armor (sangat tebal), Stack
  Phantom (teleport ke dekatmu lalu menembak). Boss **The Archivist**.
- **Crystal Cavern:** Crystal Mite, Shard Bat, Crystal Golem (menyeruduk), Prism Eye (5 tembakan berbentuk kipas).
  Boss **Crystal Colossus**.
- **Rift Nexus:** Voidling (pecah), Rift Ray (tembus tembok), Rift Horror (menyeruduk), Void Seer (teleport dan
  tembakan kipas). Boss **Rift Sovereign**.
- Setiap boss punya pola sendiri: cincin peluru, spiral, tembakan terarah, teleport, seruduk, dan memanggil anak buah.
- Codex > MONSTERS: musuh dari lokasi yang belum terbuka tampil sebagai siluet "???".
- [ ] Musuh baru mudah dikenali? Ada yang mirip karakter game/anime terkenal?
- [ ] Seruduk dan teleport adil (ada ancang-ancang yang terlihat)?
- [ ] Warna peta tiap lokasi enak dilihat?

**Tahap 5a: tingkat danger + pilih lokasi.**
- Halaman Rift: tab lokasi 1–5 (yang terkunci abu-abu) dan tombol **DANGER 1–5**. Hijau = sudah dimenangkan,
  merah = belum, abu-abu = terkunci.
- Menang Danger N membuka Danger N+1. Menang Danger 1 sebuah lokasi membuka lokasi berikutnya.
- Danger lebih tinggi: musuh lebih tebal, lebih sakit, lebih banyak, elite lebih sering, hadiah dikali (lihat
  chip hadiah "x2.2"). Ada chip **Rec. Lv** (merah kalau level karaktermu di bawah rekomendasi).
- Lokasi 2–5 untuk sementara masih memakai peta dan musuh Courtyard (konten aslinya menyusul di 5b–5e).
- Workshop: crafting Rare butuh Sylvan Essence (Whispering Forest), Epic butuh Ink Essence (Forgotten Library).
- [ ] Danger 2–3 terasa lebih susah tapi masih adil?
- [ ] Hadiah terasa sepadan dengan kesulitannya?

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
