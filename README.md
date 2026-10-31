# Riftbound: Arcane Academy — Rift Run Prototype (Godot 4)

Prototype combat run ala Megabonk: map procedural, spawn player dan portal boss acak,
chest berbayar, shrine, tome dan 6 weapon (slot mulai 2 + 2, dibuka sampai 4 + 4 lewat bangunan akademi),
elite, Rift Surge, Final Swarm, boss, minimap + peta fog-of-war, layar akademi sederhana di antara run,
4 karakter dengan stat dan pasif masing-masing, serta VFX berat (bloom HDR, partikel, shader distorsi).

APK terbaru: https://github.com/aviharez/riftbound-survivor/releases/tag/latest-build
Semua grafik masih placeholder (bentuk dasar), belum ada sprite atau suara.

Diuji dengan **Godot 4.7.2** (headless + render via OpenGL). Kode tidak memakai fitur khusus 4.7,
jadi seharusnya juga jalan di 4.4+, tapi itu belum diuji.

## Menjalankan

1. Buka Godot 4 → Import → pilih `project.godot`.
2. Tekan F5.

Kontrol PC: WASD/arrow gerak, Space dash, M peta, Esc/P pause.
Kontrol sentuh: sentuh dan geser di separuh kiri layar (joystick muncul di titik sentuh), tombol DASH di kanan bawah.
Mouse juga bisa dipakai sebagai joystick (emulate touch from mouse aktif).

Seed tertentu: jalankan dengan argumen `-- --seed=12345` (seed tampil di menu pause dan layar hasil).

## Export Android

Project → Export → Add Android (butuh Android SDK + export template sesuai versi Godot).
Orientasi sudah diset landscape, renderer `mobile`, resolusi internal 640×360 dengan skala bilangan bulat.

## Struktur

| File | Isi |
| --- | --- |
| `scripts/data/game_data.gd` | Semua angka tuning dan tabel konten (item, tome, weapon, shrine, musuh, boss, timeline) |
| `scripts/world/map_generator.gd` | Generator map deterministik dari seed + aturan penempatan objek |
| `scripts/world/world.gd` | Render map (1 tekstur), collision grid, flow field BFS untuk pathing musuh |
| `scripts/world/fog.gd` | Fog-of-war (sel 4×4 tile) untuk minimap & peta penuh |
| `scripts/world/interactables.gd` | Chest, shrine, pot, Rift Portal, Exit Portal |
| `scripts/world/effects.gd` | Angka damage |
| `scripts/actors/player.gd` | Gerak, dash, HP, stat, level tome/weapon |
| `scripts/actors/weapons.gd` | Delapan weapon (desain: Riftbound Weapon Attack Design): Arcane Bolt, Flame Orb, Chain Lightning, Meteor Fall, Astral Blades, Void Well, Frost Lance, Thornseed |
| `scripts/meta/save_data.gd` | Save permanen: resource akademi, level bangunan, riwayat run |
| `scripts/ui/academy.gd` | Layar akademi: upgrade Library (slot tome) dan Training Ground (slot weapon), masuk Rift |
| `scripts/actors/enemies.gd` | Musuh, elite, boss, peluru musuh (data-oriented, 1 node) |
| `scripts/actors/projectiles.gd` | Proyektil player + pantulan |
| `scripts/actors/pickups.gd` | XP gem, gold, heal |
| `scripts/ui/hud.gd` | HUD, joystick, minimap, peta, panah tepi layar, panel pilihan, layar hasil |
| `scripts/main.gd` | Orkestrasi run: timeline, spawn, ekonomi, shrine, boss, menang/kalah, autotest |

Menambah item/tome/shrine/musuh baru: tambahkan baris di `game_data.gd`.

## Tes otomatis

```
godot --headless --path . -s tests/test_mapgen.gd                    # 40 seed: sukses, waktu, determinisme
godot --headless --path . -s tests/test_academy.gd                   # save, upgrade bangunan, jumlah slot
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242   # jalur menang (teleport ke objektif, god mode)
godot --headless --path . --fixed-fps 60 -- --autotest-die           # jalur kalah (diam sampai mati)
godot --headless --path . --fixed-fps 60 -- --autotest-late          # portal setelah timer habis → Final Swarm
```

## Batasan yang diketahui

- Belum ada sprite, animasi, atau audio. Akademi baru berisi 2 bangunan (Library, Training Ground).
- Save tersimpan di `user://riftbound_save.json`; tombol "Reset save" (tekan 2x) di akademi untuk mulai ulang.
- Balancing belum diuji oleh manusia: angka di `game_data.gd` adalah titik awal.
- Performa diukur di CPU cloud (headless), belum di HP Android sungguhan.
