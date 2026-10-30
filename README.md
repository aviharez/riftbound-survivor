# Riftbound: Arcane Academy — Rift Run Prototype (Godot 4)

Prototype combat run ala Megabonk: map procedural, spawn player dan portal boss acak,
chest berbayar, shrine, elite, Rift Surge, Final Swarm, boss, minimap + peta fog-of-war.
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
| `scripts/data/game_data.gd` | Semua angka tuning dan tabel konten (item, upgrade, shrine, musuh, boss, timeline) |
| `scripts/world/map_generator.gd` | Generator map deterministik dari seed + aturan penempatan objek |
| `scripts/world/world.gd` | Render map (1 tekstur), collision grid, flow field BFS untuk pathing musuh |
| `scripts/world/fog.gd` | Fog-of-war (sel 4×4 tile) untuk minimap & peta penuh |
| `scripts/world/interactables.gd` | Chest, shrine, pot, Rift Portal, Exit Portal |
| `scripts/world/effects.gd` | Angka damage |
| `scripts/actors/player.gd` | Gerak, dash, auto-attack, Frost Nova, stat |
| `scripts/actors/enemies.gd` | Musuh, elite, boss, peluru musuh (data-oriented, 1 node) |
| `scripts/actors/projectiles.gd` | Proyektil player + pantulan |
| `scripts/actors/pickups.gd` | XP gem, gold, heal |
| `scripts/ui/hud.gd` | HUD, joystick, minimap, peta, panah tepi layar, panel pilihan, layar hasil |
| `scripts/main.gd` | Orkestrasi run: timeline, spawn, ekonomi, shrine, boss, menang/kalah, autotest |

Menambah item/shrine/musuh baru: tambahkan baris di `game_data.gd`.

## Tes otomatis

```
godot --headless --path . -s tests/test_mapgen.gd                    # 40 seed: sukses, waktu, determinisme
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242   # jalur menang (teleport ke objektif, god mode)
godot --headless --path . --fixed-fps 60 -- --autotest-die           # jalur kalah (diam sampai mati)
godot --headless --path . --fixed-fps 60 -- --autotest-late          # portal setelah timer habis → Final Swarm
```

## Batasan yang diketahui

- Belum ada sprite, animasi, audio, atau menu utama; layar hasil langsung menawarkan run baru.
- Reward akademi di layar hasil hanya angka; belum tersambung ke sistem akademi.
- Balancing belum diuji oleh manusia: angka di `game_data.gd` adalah titik awal.
- Performa diukur di CPU cloud (headless), belum di HP Android sungguhan.
