# R-Desk

R-Desk adalah aplikasi Flutter untuk mengelola, memproses, dan menampilkan
berbagai gambar teknis, gambar varian, serta gambar produk. Aplikasi ini ditujukan
untuk kebutuhan administrasi dan operasional yang memerlukan pencarian, pengeditan,
serta pengelolaan data gambar secara terpusat.

## Fitur Utama

- Mengelola gambar kelistrikan, gambar varian, dan gambar produk.
- Menambah dan mengedit data gambar melalui form aplikasi.
- Menampilkan data dalam tabel dengan filter dan pencarian.
- Menyimpan serta menampilkan file gambar dan resource terkait.
- Mendukung build desktop dan Flutter Web.

## Persiapan Lokal

Pastikan Flutter dan Git sudah terpasang. Lihat [Flutter Installation Guide](https://docs.flutter.dev/get-started/install) untuk instalasi Flutter.

```bash
git clone https://github.com/Zenalghi/r-desk.git
cd r-desk
flutter pub get
flutter run
```

Contoh perintah build lokal:

```bash
flutter build web --release
flutter build windows --release
```

## CI/CD GitHub Actions

Repository ini menyediakan dua workflow deploy. Keduanya hanya berjalan setelah
Anda menekan **Run workflow** secara manual di GitHub Web atau GitHub Mobile.
Trigger otomatis saat `git push` sengaja dinonaktifkan agar deploy production
tetap membutuhkan persetujuan operator.

### Opsi A: Deploy ke GitHub Pages

Workflow: `.github/workflows/deploy-gh-pages.yml`

Workflow ini berjalan di runner GitHub (`ubuntu-latest`) dan melakukan:

1. Checkout repository.
2. Menyiapkan Flutter stable.
3. Menjalankan `flutter pub get`.
4. Build Flutter Web release dengan `base-href` sesuai nama repository.
5. Mempublikasikan `build/web` ke branch `gh-pages`.

Jalankan dari GitHub:

1. Buka tab **Actions** pada repository.
2. Pilih **Deploy R-Desk to GitHub Pages**.
3. Klik **Run workflow** dan isi catatan deploy bila diperlukan.
4. Tunggu workflow selesai, lalu akses URL GitHub Pages repository.

Workflow membutuhkan permission `contents: write` untuk memperbarui branch
`gh-pages`. Aktifkan GitHub Pages dari branch tersebut pada pengaturan repository
jika belum aktif.

### Opsi B: Update Otomatis via CI/CD di SOHO

Workflow: `.github/workflows/deploy-web-soho.yml`

Opsi ini direkomendasikan untuk deployment SOHO karena proses update berjalan di
VM atau homeserver sendiri melalui **self-hosted runner**. Tidak diperlukan SSH
ke server, IP server, SSH key, atau database secret di GitHub Actions. Workflow
menjalankan perintah langsung pada server:

```bash
cd /srv/workspace/apps/r-desk-web
git pull origin main || git pull origin master
docker compose -f docker-compose.web.yml up -d --build
docker compose -f docker-compose.web.yml ps
```

#### Persiapan self-hosted runner satu kali

1. Buka repository di GitHub, lalu masuk ke **Settings > Actions > Runners**.
2. Klik **New self-hosted runner**, pilih **Linux** dan arsitektur `x64`.
3. Di terminal server, buat folder runner terpisah dari folder aplikasi:

   ```bash
   mkdir -p ~/runner-r-desk && cd ~/runner-r-desk
   ```

4. Jalankan perintah `curl`, `tar`, dan `./config.sh` yang diberikan GitHub
   pada halaman runner. Gunakan label default `self-hosted` agar cocok dengan
   `runs-on: self-hosted` pada workflow.
5. Setelah konfigurasi selesai, pasang runner sebagai service agar aktif kembali
   saat server reboot:

   ```bash
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

Folder runner harus berbeda dari `/srv/workspace/apps/r-desk-web`. Folder aplikasi
tersebut wajib sudah tersedia di server dan memiliki `docker-compose.web.yml`,
akses Git ke repository, serta akses Docker bagi user service runner.

#### Menjalankan update SOHO

1. Pastikan runner terlihat **Idle** di **Settings > Actions > Runners**.
2. Buka tab **Actions** dan pilih **Safe Deploy R-Desk Web (SOHO Production)**.
3. Klik **Run workflow**, lalu isi catatan deploy bila diperlukan.
4. Periksa langkah verifikasi **Verifikasi Status Kontainer** sampai selesai.

Workflow memperbarui frontend web dan membangun ulang container tanpa mengganggu
backend. Sebelum menjalankan deploy pertama, pastikan konfigurasi production,
volume, dan backup aplikasi sudah disiapkan di server.

#### Pemeriksaan manual di server

```bash
cd /srv/workspace/apps/r-desk-web
docker compose -f docker-compose.web.yml ps
docker compose -f docker-compose.web.yml logs -f
```

Jika workflow gagal, periksa status service runner, hasil `git pull`, izin Docker,
serta ketersediaan file `docker-compose.web.yml` pada folder aplikasi.

## Struktur Workflow

| Workflow | Runner | Hasil |
| --- | --- | --- |
| `deploy-gh-pages.yml` | GitHub-hosted | Flutter Web di branch `gh-pages` |
| `deploy-web-soho.yml` | Self-hosted SOHO | Container frontend di server SOHO |

## Keamanan Deployment

- Biarkan deploy tetap manual kecuali proses otomatis memang sudah disetujui.
- Jangan commit password, token, atau file `.env` ke repository.
- Jalankan self-hosted runner dengan user khusus dan izin Docker seperlunya.
- Pastikan backup aplikasi tersedia sebelum rebuild container production.
