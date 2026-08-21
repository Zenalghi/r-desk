// File: lib/elements/home/widgets/tambah_transaksi_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dio/dio.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/elements/home/providers/transaksi_providers.dart';
import 'package:master_gambar/elements/home/repository/options_repository.dart';
import '../../../app/core/notifiers/refresh_notifier.dart';

class TambahTransaksiDialog extends ConsumerStatefulWidget {
  final VoidCallback onTransaksiAdded;

  const TambahTransaksiDialog({super.key, required this.onTransaksiAdded});

  @override
  ConsumerState<TambahTransaksiDialog> createState() =>
      _TambahTransaksiDialogState();
}

class _TambahTransaksiDialogState extends ConsumerState<TambahTransaksiDialog> {
  final _formKey = GlobalKey<FormState>();

  // Kita hanya butuh 3 state sekarang
  int? _selectedCustomerId;
  int? _selectedMasterDataId;
  int? _selectedJenisPengajuanId;

  void _resetAndRefresh() {
    setState(() {
      _selectedCustomerId = null;
      _selectedMasterDataId = null;
      _selectedJenisPengajuanId = null;
    });
    ref.read(refreshNotifierProvider.notifier).refresh();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Panggil repository dengan parameter baru
        await ref
            .read(optionsRepositoryProvider)
            .addTransaksi(
              customerId: _selectedCustomerId!,
              masterDataId: _selectedMasterDataId!,
              jenisPengajuanId: _selectedJenisPengajuanId!,
            );

        widget.onTransaksiAdded();

        if (mounted) Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menambah transaksi: ${e.response?.data['message'] ?? e.message}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tambah Transaksi Baru'),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: _resetAndRefresh,
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CUSTOMER
              // 1. CUSTOMER (SEARCHABLE)
              DropdownSearch<OptionItem>(
                // Panggil provider family dengan teks filter
                items: (String filter, _) =>
                    ref.read(customerOptionsSearchProvider(filter).future),
                itemAsString: (OptionItem item) => item.name,
                compareFn: (i1, i2) => i1.id == i2.id,
                onChanged: (OptionItem? item) {
                  setState(() => _selectedCustomerId = item?.id as int?);
                },
                selectedItem: null,
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
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
                validator: (item) => item == null && _selectedCustomerId == null
                    ? 'Wajib dipilih'
                    : null,
              ),

              const SizedBox(height: 16),

              // 2. MASTER DATA KENDARAAN (Searchable Dropdown)
              DropdownSearch<OptionItem>(
                items: (String filter, _) =>
                    ref.read(transaksiMasterDataOptionsProvider(filter).future),
                itemAsString: (OptionItem item) => item.name,
                // --- PERBAIKAN: Tambahkan compareFn ---
                compareFn: (i1, i2) => i1.id == i2.id,
                // ------------------------------------
                onChanged: (OptionItem? item) {
                  setState(() => _selectedMasterDataId = item?.id as int?);
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
                    labelText:
                        'Pilih Kendaraan (Engine / Merk / Chassis / Jenis)',
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
                      hintText: "Cari kendaraan...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
                validator: (item) =>
                    item == null && _selectedMasterDataId == null
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
                    setState(() => _selectedJenisPengajuanId = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Simpan Transaksi'),
        ),
      ],
    );
  }

  // Helper untuk dropdown biasa (Customer & Pengajuan)
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
}
