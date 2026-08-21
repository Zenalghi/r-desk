// File: lib/elements/home/widgets/edit_transaksi_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/app/core/providers.dart';
// import 'package:dio/dio.dart';
import 'package:master_gambar/data/models/transaksi.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/elements/home/providers/transaksi_providers.dart';
import 'package:master_gambar/elements/home/repository/options_repository.dart';

class EditTransaksiDialog extends ConsumerStatefulWidget {
  final Transaksi transaksi;

  const EditTransaksiDialog({super.key, required this.transaksi});

  @override
  ConsumerState<EditTransaksiDialog> createState() =>
      _EditTransaksiDialogState();
}

class _EditTransaksiDialogState extends ConsumerState<EditTransaksiDialog> {
  final _formKey = GlobalKey<FormState>();

  // State lokal
  late int _selectedCustomerId;
  late int _selectedMasterDataId;
  late int _selectedJenisPengajuanId;
  late String _selectedPdfDateType;
  late DateTime _selectedCreatedAt;

  // Untuk tampilan awal dropdown Master Data
  late OptionItem _initialMasterDataOption;
  late OptionItem _initialCustomerOption;
  @override
  void initState() {
    super.initState();
    // 1. Isi ID
    _selectedCustomerId = widget.transaksi.customer.id;
    _selectedMasterDataId = widget.transaksi.masterDataId;
    _selectedJenisPengajuanId = widget.transaksi.fPengajuan.id;
    _selectedPdfDateType = widget.transaksi.pdfDateType;
    _selectedCreatedAt = widget.transaksi.createdAt.toLocal();

    // 2. Buat object OptionItem untuk tampilan awal DropdownSearch
    // Gabungkan nama A/B/C/D yang sudah ada di transaksi
    final displayName =
        "${widget.transaksi.aTypeEngine.typeEngine} / "
        "${widget.transaksi.bMerk.merk} / "
        "${widget.transaksi.cTypeChassis.displayName} / "
        "${widget.transaksi.dJenisKendaraan.jenisKendaraan}";

    _initialMasterDataOption = OptionItem(
      id: _selectedMasterDataId,
      name: displayName,
    );
    _initialCustomerOption = OptionItem(
      id: widget.transaksi.customer.id,
      name: widget.transaksi.customer.namaPt,
    );
  }

  void _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(transaksiRepositoryProvider)
            .updateTransaksi(
              transaksiId: widget.transaksi.id,
              customerId: _selectedCustomerId,
              masterDataId: _selectedMasterDataId, // Kirim ID Master Data
              jenisPengajuanId: _selectedJenisPengajuanId,
              pdfDateType: _selectedPdfDateType,
              createdAt: _selectedCreatedAt.toIso8601String(),
            );

        if (mounted) Navigator.of(context).pop();

        // Gunakan dataSource provider untuk refresh yang benar
        // (Pastikan Anda mengimport file datasource jika perlu)
        // Atau invalidate history provider
        ref.invalidate(transaksiFilterProvider); // Cara refresh via filter
        // Atau jika menggunakan DataSource:
        // ref.read(transaksiDataSourceProvider).refreshDatasource();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal update: $e',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Anda yakin ingin menghapus transaksi ID: ${widget.transaksi.id}? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ya, Hapus'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitDelete();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitDelete() async {
    try {
      await ref
          .read(transaksiRepositoryProvider)
          .deleteTransaksi(transaksiId: widget.transaksi.id);
      if (mounted) Navigator.of(context).pop();
      ref.invalidate(transaksiFilterProvider); // Refresh tabel
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus transaksi: $e',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final isAdmin = authService.canViewAdminTabs();
    final isSaved = widget.transaksi.detail != null;

    return AlertDialog(
      title: Text('Edit Transaksi: ${widget.transaksi.id}'),
      content: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSaved) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customer dan Kendaraan tidak dapat diubah karena detail transaksi sudah dibuat.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. CUSTOMER (SEARCHABLE)
                DropdownSearch<OptionItem>(
                  enabled: !isSaved,
                  items: (String filter, _) =>
                      ref.read(customerOptionsSearchProvider(filter).future),
                  itemAsString: (OptionItem item) => item.name,
                  compareFn: (i1, i2) => i1.id == i2.id,
                  // Gunakan nilai awal agar terisi saat edit
                  selectedItem: _initialCustomerOption,
                  onChanged: (OptionItem? item) {
                    if (item != null) {
                      setState(() => _selectedCustomerId = item.id as int);
                    }
                  },
                  decoratorProps: const DropDownDecoratorProps(
                    baseStyle: TextStyle(fontSize: 13, height: 1.0),
                    decoration: InputDecoration(
                      constraints: BoxConstraints(maxHeight: 42),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      labelStyle: TextStyle(fontSize: 12),
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      autofocus: true,
                      style: TextStyle(fontSize: 13, height: 1.0),
                      decoration: InputDecoration(
                        constraints: BoxConstraints(maxHeight: 42),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        hintStyle: TextStyle(fontSize: 13, height: 1.0),
                        hintText: "Cari Customer...",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    itemBuilder: (context, item, isSelected, isDisabled) {
                      final hasSut = item.data != null && item.data!['nomor_sut'] != null && item.data!['nomor_sut'].toString().isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.0,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasSut) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Nomor SUT: ${item.data!['nomor_sut']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  validator: (item) => item == null ? 'Wajib dipilih' : null,
                ),

                const SizedBox(height: 16),

                // 2. MASTER DATA (DropdownSearch)
                DropdownSearch<OptionItem>(
                  enabled: !isSaved,
                  items: (String filter, _) => ref.read(
                    transaksiMasterDataOptionsProvider(filter).future,
                  ),
                  itemAsString: (OptionItem item) => item.name,
                  compareFn: (i1, i2) => i1.id == i2.id, // Penting!
                  selectedItem: _initialMasterDataOption, // Nilai awal
                  onChanged: (OptionItem? item) {
                    if (item != null) {
                      setState(() => _selectedMasterDataId = item.id as int);
                    }
                  },
                  decoratorProps: const DropDownDecoratorProps(
                    baseStyle: TextStyle(fontSize: 13, height: 1.0),
                    decoration: InputDecoration(
                      constraints: BoxConstraints(maxHeight: 42),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      labelStyle: TextStyle(fontSize: 12),
                      labelText: 'Kendaraan (Engine / Merk / Chassis / Jenis)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      autofocus: true,
                      style: TextStyle(fontSize: 13, height: 1.0),
                      decoration: InputDecoration(
                        constraints: BoxConstraints(maxHeight: 42),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        hintStyle: TextStyle(fontSize: 13, height: 1.0),
                        hintText: "Cari...",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    itemBuilder: (context, item, isSelected, isDisabled) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        height:
                            30, // Paksa tinggi item menjadi 30px (atau lebih kecil sesuai selera)
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.0,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                  validator: (item) =>
                      item == null && _selectedMasterDataId == 0
                      ? 'Wajib dipilih'
                      : null,
                ),

                const SizedBox(height: 16),

                // 3. JENIS PENGAJUAN
                _buildStandardDropdown(
                  label: 'Jenis Pengajuan',
                  optionsProvider: jenisPengajuanOptionsProvider,
                  selectedValue: _selectedJenisPengajuanId,
                  onChanged: (val) =>
                      setState(() => _selectedJenisPengajuanId = val!),
                ),

                const SizedBox(height: 16),

                _buildDateDropdown(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _showDeleteConfirmationDialog,
              child: const Text('Hapus'),
            ),
            const SizedBox(width: 8),
            if (isAdmin)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                icon: const Icon(Icons.edit_calendar, size: 14),
                label: const Text(
                  'Ubah Tanggal Pembuatan',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedCreatedAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialEntryMode: DatePickerEntryMode.input,
                    locale: const Locale('id', 'ID'),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedCreatedAt = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        _selectedCreatedAt.hour,
                        _selectedCreatedAt.minute,
                      );
                    });
                  }
                },
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  '* Hubungi admin untuk ubah tanggal pembuatan',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _submitUpdate,
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardDropdown({
    required String label,
    required FutureProvider<List<OptionItem>> optionsProvider,
    required int? selectedValue,
    required Function(int?) onChanged,
  }) {
    final optionsAsync = ref.watch(optionsProvider);

    return optionsAsync.when(
      data: (items) {
        // Cari item yang sesuai dengan ID yang terpilih
        final selectedItem = items
            .where((e) => e.id == selectedValue)
            .firstOrNull;

        return DropdownSearch<OptionItem>(
          // Data list langsung dari items (tanpa filter async karena tidak ada search)
          items: (filter, _) => items,

          itemAsString: (OptionItem item) => item.name,
          compareFn: (i1, i2) => i1.id == i2.id,
          selectedItem: selectedItem,

          onChanged: (OptionItem? item) {
            onChanged(item?.id as int?);
          },

          // --- TAMPILAN FIELD (32px) ---
          decoratorProps: DropDownDecoratorProps(
            baseStyle: const TextStyle(fontSize: 13, height: 1.0),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 12),
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(maxHeight: 42),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              isDense: true,
            ),
          ),

          // --- TAMPILAN POPUP (Tanpa Search & Item Pendek) ---
          popupProps: PopupProps.menu(
            // 1. MATIKAN SEARCH BOX DI SINI
            showSearchBox: false,

            fit: FlexFit.loose,
            constraints: const BoxConstraints(
              maxHeight: 300,
            ), // Batas tinggi popup
            menuProps: const MenuProps(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),

            // 2. Custom Item Builder (Agar item list jadi pendek 30px)
            itemBuilder: (context, item, isSelected, isDisabled) {
              final hasSut = item.data != null && item.data!['nomor_sut'] != null && item.data!['nomor_sut'].toString().isNotEmpty;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                alignment: Alignment.centerLeft,
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSut) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Nomor SUT: ${item.data!['nomor_sut']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          validator: (item) => item == null ? 'Wajib diisi' : null,
        );
      },
      // Loading State yang ukurannya pas
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox(
        height: 32,
        child: Center(
          child: Text(
            'Error',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDropdown() {
    final todayStr = DateFormat('dd.MM.yy').format(DateTime.now());
    final createdStr = DateFormat('dd.MM.yy').format(_selectedCreatedAt);

    final items = ['today', 'created_at'];

    return DropdownSearch<String>(
      items: (filter, _) => items,
      itemAsString: (String item) {
        if (item == 'today') return 'Hari ini ($todayStr)';
        return 'Tanggal Pembuatan ($createdStr)';
      },
      selectedItem: _selectedPdfDateType,
      onChanged: (String? val) {
        if (val != null) {
          setState(() {
            _selectedPdfDateType = val;
          });
        }
      },
      decoratorProps: const DropDownDecoratorProps(
        baseStyle: TextStyle(fontSize: 13, height: 1.0),
        decoration: InputDecoration(
          labelText: 'Tanggal Cetak PDF',
          labelStyle: TextStyle(fontSize: 12),
          border: OutlineInputBorder(),
          constraints: BoxConstraints(maxHeight: 42),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          isDense: true,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 150),
        menuProps: const MenuProps(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        itemBuilder: (context, item, isSelected, isDisabled) {
          final displayText = item == 'today'
              ? 'Hari ini ($todayStr)'
              : 'Tanggal Pembuatan ($createdStr)';
          return Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}
