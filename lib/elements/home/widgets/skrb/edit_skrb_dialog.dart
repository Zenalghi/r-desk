// File: lib/elements/home/widgets/skrb/edit_skrb_dialog.dart
// Dialog untuk mengedit data inti SKRB (Customer, Kendaraan, Jenis Pengajuan) dan Nomor Urut / ID SKRB.
// Digunakan dari tabel Permohonan SKRB ketika icon edit ditekan.

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/data/models/skrb.dart';
import 'package:master_gambar/elements/home/providers/skrb_providers.dart';
import 'package:master_gambar/elements/home/providers/transaksi_providers.dart';
import 'package:master_gambar/elements/home/repository/skrb_repository.dart';
import 'card_id_skrb_setting.dart';

class EditSkrbDialog extends ConsumerStatefulWidget {
  final Skrb skrb;

  const EditSkrbDialog({super.key, required this.skrb});

  @override
  ConsumerState<EditSkrbDialog> createState() => _EditSkrbDialogState();
}

class _EditSkrbDialogState extends ConsumerState<EditSkrbDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  bool _loading = false;

  int? _selectedCustomerId;
  int? _selectedMasterDataId;
  int? _selectedJenisPengajuanId;
  String? _customerName;

  bool _loadingPreview = false;
  String? _previewError;
  String? _previewIdSkrb;

  @override
  void initState() {
    super.initState();
    // Pre-populate dari data SKRB saat ini
    _selectedCustomerId = widget.skrb.customerId;
    _selectedMasterDataId = widget.skrb.masterDataId;
    _selectedJenisPengajuanId = widget.skrb.jenisPengajuanId;
    _customerName = widget.skrb.customerName;
    _previewIdSkrb = widget.skrb.idSkrb;
  }

  @override
  void dispose() {
    _nomorController.dispose();
    super.dispose();
  }

  void _onCustomerChanged(OptionItem? item) {
    setState(() {
      _selectedCustomerId = item?.id as int?;
      _customerName = item?.name ?? widget.skrb.customerName;
    });
    if (_selectedCustomerId != null) {
      if (_selectedCustomerId == widget.skrb.customerId) {
        setState(() {
          _previewIdSkrb = widget.skrb.idSkrb;
          _loadingPreview = false;
          _previewError = null;
        });
      } else {
        _loadPreviewId(_selectedCustomerId!);
      }
    } else {
      setState(() {
        _previewIdSkrb = null;
      });
    }
  }

  Future<void> _loadPreviewId(int customerId) async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final repo = ref.read(skrbRepositoryProvider);
      final result = await repo.getPreviewIdSkrb(customerId);
      if (mounted && _selectedCustomerId == customerId) {
        setState(() {
          _previewIdSkrb = result['preview_id_skrb'] as String?;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted && _selectedCustomerId == customerId) {
        setState(() {
          _previewError = e.toString();
          _loadingPreview = false;
        });
      }
    }
  }

  int? _parseNomor() {
    final raw = _nomorController.text.trim();
    if (raw.isEmpty) return null;
    final val = int.tryParse(raw);
    if (val == null || val < 1) return null;
    return val;
  }

  Future<void> _handleSimpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(skrbRepositoryProvider);
      await repo.updateSkrbData(
        widget.skrb.id,
        customerId: _selectedCustomerId,
        masterDataId: _selectedMasterDataId,
        jenisPengajuanId: _selectedJenisPengajuanId,
        nomorUrutManual: _parseNomor(),
      );
      // Invalidate providers agar list & detail reload
      ref.invalidate(skrbListProvider);
      ref.invalidate(skrbDetailProvider(widget.skrb.id));
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Data SKRB berhasil diperbarui!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message']?.toString() ?? e.message ?? 'Terjadi kesalahan.';
      final isDuplicate = msg.toLowerCase().contains('sudah terdaftar') ||
          msg.toLowerCase().contains('duplikat') ||
          msg.toLowerCase().contains('duplicate') ||
          msg.toLowerCase().contains('sudah digunakan') ||
          msg.toLowerCase().contains('unik');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(isDuplicate ? Icons.warning_amber_rounded : Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(isDuplicate ? '⚠️ Peringatan: $msg' : 'Gagal menyimpan: $msg', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: isDuplicate ? Colors.orange.shade800 : Colors.red,
            duration: Duration(seconds: isDuplicate ? 5 : 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      final isDuplicate = msg.toLowerCase().contains('sudah terdaftar') ||
          msg.toLowerCase().contains('duplikat') ||
          msg.toLowerCase().contains('duplicate') ||
          msg.toLowerCase().contains('sudah digunakan') ||
          msg.toLowerCase().contains('unik');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(isDuplicate ? Icons.warning_amber_rounded : Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(isDuplicate ? '⚠️ Peringatan: $msg' : 'Error: $msg', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: isDuplicate ? Colors.orange.shade800 : Colors.red,
            duration: Duration(seconds: isDuplicate ? 5 : 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Icon(
            Icons.edit_document,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Edit Data SKRB',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info SKRB
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ID SKRB: ${widget.skrb.idSkrb}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (widget.skrb.transaksiId.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.receipt_long,
                          size: 13,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ID DWG: ${widget.skrb.transaksiId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. CUSTOMER
                DropdownSearch<OptionItem>(
                  items: (String filter, _) =>
                      ref.read(customerOptionsSearchProvider(filter).future),
                  itemAsString: (OptionItem item) => item.name,
                  compareFn: (i1, i2) => i1.id == i2.id,
                  selectedItem: _selectedCustomerId != null
                      ? OptionItem(
                          id: _selectedCustomerId!,
                          name: _customerName ?? widget.skrb.customerName,
                        )
                      : null,
                  onChanged: _onCustomerChanged,
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
                        hintText: 'Cari Customer...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    menuProps: const MenuProps(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    itemBuilder: (context, item, isSelected, isDisabled) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        height: 30,
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
                  validator: (item) => item == null && _selectedCustomerId == null
                      ? 'Wajib dipilih'
                      : null,
                ),

                const SizedBox(height: 14),

                // 2. MASTER DATA KENDARAAN
                DropdownSearch<OptionItem>(
                  items: (String filter, _) =>
                      ref.read(transaksiMasterDataOptionsProvider(filter).future),
                  itemAsString: (OptionItem item) => item.name,
                  compareFn: (i1, i2) => i1.id == i2.id,
                  selectedItem: _selectedMasterDataId != null
                      ? OptionItem(
                          id: _selectedMasterDataId!,
                          name:
                              '${widget.skrb.typeEngine} / ${widget.skrb.merk} / ${widget.skrb.chassisDisplayName} / ${widget.skrb.jenisKendaraan}',
                        )
                      : null,
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
                        hintText: 'Cari kendaraan...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    menuProps: const MenuProps(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    itemBuilder: (context, item, isSelected, isDisabled) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        height: 30,
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
                      item == null && _selectedMasterDataId == null
                      ? 'Wajib dipilih'
                      : null,
                ),

                const SizedBox(height: 14),

                // 3. JENIS PENGAJUAN
                _buildPengajuanDropdown(),

                if (_selectedCustomerId != null) ...[
                  const SizedBox(height: 18),
                  CardIdSkrbSetting(
                    isEditMode: true,
                    customerName: _customerName ?? widget.skrb.customerName,
                    loadingPreview: _loadingPreview,
                    previewError: _previewError,
                    previewIdSkrb: _previewIdSkrb,
                    nomorController: _nomorController,
                    onChanged: (_) => setState(() {}),
                  ),
                ],

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) {
            final isNomorSet =
                _nomorController.text.trim().isNotEmpty && _parseNomor() != null;
            return Row(
              children: [
                if (isNomorSet) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ubah nomor urut (${_nomorController.text.trim().padLeft(2, '0')})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loading ? null : _handleSimpan,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPengajuanDropdown() {
    final optionsAsync = ref.watch(jenisPengajuanOptionsProvider);
    return optionsAsync.when(
      data: (items) {
        final filteredItems = items.where((e) => e.id != 4).toList();
        final selectedItem = filteredItems
            .where((e) => e.id == _selectedJenisPengajuanId)
            .firstOrNull;
        return DropdownSearch<OptionItem>(
          items: (filter, _) => filteredItems,
          itemAsString: (OptionItem item) => item.name,
          compareFn: (i1, i2) => i1.id == i2.id,
          selectedItem: selectedItem,
          onChanged: (OptionItem? item) {
            setState(() => _selectedJenisPengajuanId = item?.id as int?);
          },
          decoratorProps: DropDownDecoratorProps(
            baseStyle: const TextStyle(fontSize: 13, height: 1.0),
            decoration: InputDecoration(
              labelText: 'Jenis Pengajuan',
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
          popupProps: PopupProps.menu(
            showSearchBox: false,
            fit: FlexFit.loose,
            constraints: const BoxConstraints(maxHeight: 250),
            menuProps: const MenuProps(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            itemBuilder: (context, item, isSelected, isDisabled) {
              return Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          validator: (item) => item == null ? 'Wajib diisi' : null,
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox(
        height: 32,
        child: Center(
          child: Text(
            'Error memuat jenis pengajuan',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
