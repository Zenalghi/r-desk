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
- Mendukung build desktop, Flutter Web, dan deployment SOHO via Docker + Nginx Proxy Manager.

## Best Practice Deployment SOHO

Untuk lingkungan LAN/SOHO, praktik terbaik adalah menjaga frontend dan backend
sebagai dua layanan terpisah, tetapi membuka satu origin yang sama untuk browser.
Dengan pola ini, semua klien hanya membuka satu URL dan tidak perlu konfigurasi
manual pada tiap PC.

```text
http://192.168.100.207/
   /       -> r-desk-web:80
   /api    -> master-gambar-nginx:80
   /storage -> master-gambar-nginx:80
```

### Kenapa pola ini paling aman dan praktis?

- Browser tidak memblokir request karena origin tetap sama.
- Tidak perlu `hosts` file, `config.json`, atau script tambahan di 20 PC client.
- API tetap dipisah dari frontend secara arsitektur, tetapi diakses melalui satu
  domain/URL internal.
- Deployment produksi lebih mudah dipelihara dan lebih aman untuk jaringan lokal.

> Prinsipnya: frontend dan backend tetap terpisah secara container, tetapi user
> hanya melihat satu origin yang sama di browser.

## Persiapan Lokal untuk Developer

Untuk pengembangan lokal, instal Flutter dan Git di mesin pengembang. Lihat
[Flutter Installation Guide](https://docs.flutter.dev/get-started/install).

```bash
git clone https://github.com/Zenalghi/r-desk.git
cd r-desk
flutter pub get
flutter run
```

Contoh build lokal:

```bash
flutter build web --release
flutter build windows --release
```

## Persiapan Server Produksi

Untuk server produksi SOHO, tidak perlu menginstall Flutter di host. Proses build
frontend dilakukan di Docker multi-stage. Yang dibutuhkan hanya:

- Docker
- Docker Compose
- Git
- Akses ke repository GitHub
- Self-hosted runner (jika memakai GitHub Actions)

### Clone repository pada server

Pastikan folder aplikasi ada di server dengan struktur yang konsisten:

```bash
mkdir -p /srv/workspace/apps
cd /srv/workspace/apps
git clone https://github.com/Zenalghi/r-desk r_desk
cd /srv/workspace/apps/r_desk
```

Folder runner harus dipisah dari folder aplikasi, misalnya:

```bash
mkdir -p ~/runner-r-desk && cd ~/runner-r-desk
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

### Opsi B: Update Otomatis via CI/CD (GitHub Actions) ⭐ Rekomendasi SOHO

Workflow: `.github/workflows/deploy-web-soho.yml`

Opsi ini direkomendasikan untuk deployment SOHO karena proses update berjalan di
VM atau homeserver sendiri melalui **self-hosted runner**. Tidak diperlukan SSH
ke server, IP server, SSH key, atau database secret di GitHub Actions. Workflow
menjalankan perintah langsung pada server. Build Flutter Web dilakukan di dalam
Docker multi-stage, jadi server fresh install tidak perlu memasang Flutter:

```bash
cd /srv/workspace/apps/r_desk
git pull --ff-only origin main || git pull --ff-only origin master
docker compose -f docker-compose.web.yml up -d --build
docker compose -f docker-compose.web.yml ps
```

Image builder Docker menggunakan Flutter stable untuk menjalankan `flutter pub get`
dan `flutter build web --release`, kemudian image Nginx production hanya membawa
hasil `build/web`. Server tetap membutuhkan Docker, Docker Compose, Git, dan akses
ke repository.

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

Folder runner harus berbeda dari `/srv/workspace/apps/r_desk`. Folder aplikasi
tersebut wajib sudah tersedia di server dan memiliki `docker-compose.web.yml`,
akses Git ke repository, serta akses Docker bagi user service runner. Flutter tidak
perlu terpasang pada host karena proses build terjadi di Docker.

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
cd /srv/workspace/apps/r_desk
docker compose -f docker-compose.web.yml ps
docker compose -f docker-compose.web.yml logs -f
```

Jika workflow gagal, periksa status service runner, hasil `git pull`, izin Docker,
serta ketersediaan file `docker-compose.web.yml` pada folder aplikasi.

## Konfigurasi Nginx Proxy Manager untuk LAN

Gunakan Nginx Proxy Manager (NPM) sebagai satu-satunya pintu akses dari seluruh
PC LAN. Frontend dan backend tetap berada di container terpisah, tetapi browser
melihat keduanya sebagai satu origin:

```text
http://192.168.100.207/
   /       -> r-desk-web:80
   /api    -> master-gambar-nginx:80
   /storage -> master-gambar-nginx:80
```

Dengan pola ini, 20 PC client tidak perlu hosts file, `config.json`, instalasi
Flutter, atau script tambahan. Flutter Web production otomatis memakai origin
yang sedang dibuka dan membentuk URL API menjadi:

```text
http://192.168.100.207/api
```

### Setup Proxy Host

Di panel NPM (`http://192.168.100.207:81`):

1. Buka **Hosts > Proxy Hosts > Add Proxy Host**.
2. Pada **Domain Names**, isi `192.168.100.207`.
3. Pada **Forward Hostname/IP**, isi `r-desk-web`.
4. Pada **Forward Port**, isi `80`.
5. Aktifkan **Websockets Support** bila aplikasi membutuhkannya.
6. Simpan Proxy Host.

### Routing API melalui Custom Location

Pada Proxy Host yang sama, buka tab **Custom Locations**, lalu tambahkan:

- **Define location:** `/api`
- **Forward Hostname/IP:** `master-gambar-nginx`
- **Forward Port:** `80`

Tambahkan lokasi kedua bila diperlukan:

- **Define location:** `/storage`
- **Forward Hostname/IP:** `master-gambar-nginx`
- **Forward Port:** `80`

Simpan perubahan dan pastikan status Proxy Host **Online**. Jangan mengubah
prefix `/api`; Laravel memang mendaftarkan endpoint login sebagai
`POST /api/login`.

### Syarat Network Docker

NPM, `r-desk-web`, dan `master-gambar-nginx` harus terhubung ke network Docker
eksternal yang sama:

```bash
docker network inspect rekayasa-network
```

Nama `r-desk-web` dan `master-gambar-nginx` harus dapat di-resolve dari container
NPM. Karena service tidak membuka port langsung ke host, jangan meneruskan NPM
ke `localhost`; gunakan nama container pada network bersama.

### Verifikasi dari Server dan Client

Jalankan dari server:

```bash
curl -I http://192.168.100.207/
curl -I http://192.168.100.207/health
curl -i -X OPTIONS http://192.168.100.207/api/login \
   -H 'Origin: http://192.168.100.207' \
   -H 'Access-Control-Request-Method: POST' \
   -H 'Access-Control-Request-Headers: content-type'
```

Kemudian dari PC client buka:

```text
http://192.168.100.207/
```

Gunakan IP server yang statis atau DHCP reservation agar alamat tersebut tidak
berubah. `APP_URL` Laravel juga harus menggunakan root origin, misalnya
`http://192.168.100.207`, bukan `http://192.168.100.207/api`.

> **Catatan HTTPS:** Jika NPM frontend sudah menggunakan HTTPS, API juga harus
> diakses melalui origin HTTPS yang sama. Jangan membuat halaman HTTPS memanggil
> API HTTP karena browser akan memblokirnya sebagai mixed content.

## Struktur Workflow

| Workflow | Runner | Hasil |
| --- | --- | --- |
| `deploy-gh-pages.yml` | GitHub-hosted | Flutter Web di branch `gh-pages` |
| `deploy-web-soho.yml` | Self-hosted SOHO | Container frontend di server SOHO |

## Keamanan Deployment

- Biarkan deploy tetap manual kecuali proses otomatis memang sudah disetujui.
- Jangan commit password, token, atau file `.env` ke repository.
- Jalankan self-hosted runner dengan user khusus dan izin Docker seperlunya.
- Tetap gunakan backup aplikasi sebelum rebuild container production.
- Hindari memberitahu client untuk mengubah konfigurasi host atau file lokal pada tiap PC.
