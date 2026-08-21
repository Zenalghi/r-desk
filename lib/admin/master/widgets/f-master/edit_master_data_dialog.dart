// File: lib/admin/master/widgets/edit_master_data_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:master_gambar/admin/master/models/master_data.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';

class EditMasterDataDialog extends ConsumerStatefulWidget {
  final MasterData masterData;

  const EditMasterDataDialog({super.key, required this.masterData});

  @override
  ConsumerState<EditMasterDataDialog> createState() =>
      _EditMasterDataDialogState();
}

class _EditMasterDataDialogState extends ConsumerState<EditMasterDataDialog> {
  final _formKey = GlobalKey<FormState>();

  // Gunakan OptionItem seperti di Add Form
  OptionItem? _selectedTypeEngine;
  OptionItem? _selectedMerk;
  OptionItem? _selectedTypeChassis;
  OptionItem? _selectedJenisKendaraan;

  @override
  void initState() {
    super.initState();
    // Inisialisasi state dengan data yang ada
    _selectedTypeEngine = OptionItem(
      id: widget.masterData.typeEngine.id,
      name: widget.masterData.typeEngine.name,
    );
    _selectedMerk = OptionItem(
      id: widget.masterData.merk.id,
      name: widget.masterData.merk.name,
    );
    _selectedTypeChassis = OptionItem(
      id: widget.masterData.typeChassis.id,
      name: widget.masterData.typeChassis.displayName,
    );
    _selectedJenisKendaraan = OptionItem(
      id: widget.masterData.jenisKendaraan.id,
      name: widget.masterData.jenisKendaraan.name,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(masterDataRepositoryProvider)
          .updateMasterData(
            id: widget.masterData.id,
            // Pastikan kirim ID sebagai INT, sama seperti di Add Form
            typeEngineId: _selectedTypeEngine!.id as int,
            merkId: _selectedMerk!.id as int,
            typeChassisId: _selectedTypeChassis!.id as int,
            jenisKendaraanId: _selectedJenisKendaraan!.id as int,
          );

      // Refresh tabel di parent
      ref
          .read(masterDataFilterProvider.notifier)
          .update((state) => Map.from(state));

      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Master Data berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.response?.data['message'] ?? e.message}',
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
      title: Text('Edit Master Data #${widget.masterData.id}'),
      content: SizedBox(
        width: 500, // Lebar dialog
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchableDropdown(
                  label: 'Type Engine',
                  provider: mdTypeEngineOptionsProvider,
                  selectedItem: _selectedTypeEngine,
                  onChanged: (val) => _selectedTypeEngine = val,
                ),
                const SizedBox(height: 16),
                _buildSearchableDropdown(
                  label: 'Merk',
                  provider: mdMerkOptionsProvider,
                  selectedItem: _selectedMerk,
                  onChanged: (val) => _selectedMerk = val,
                ),
                const SizedBox(height: 16),
                _buildSearchableDropdown(
                  label: 'Type Chassis',
                  provider: mdTypeChassisOptionsProvider,
                  selectedItem: _selectedTypeChassis,
                  onChanged: (val) => _selectedTypeChassis = val,
                ),
                const SizedBox(height: 16),
                _buildSearchableDropdown(
                  label: 'Jenis Kendaraan',
                  provider: mdJenisKendaraanOptionsProvider,
                  selectedItem: _selectedJenisKendaraan,
                  onChanged: (val) => _selectedJenisKendaraan = val,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }

  // Helper yang sama persis dengan AddForm
  Widget _buildSearchableDropdown({
    required String label,
    required FutureProviderFamily<List<OptionItem>, String> provider,
    required OptionItem? selectedItem,
    required Function(OptionItem?) onChanged,
  }) {
    return DropdownSearch<OptionItem>(
      items: (String filter, _) => ref.read(provider(filter).future),
      itemAsString: (OptionItem item) => item.name,
      compareFn: (item1, item2) => item1.id == item2.id,
      selectedItem: selectedItem,
      onChanged: onChanged,
      decoratorProps: DropDownDecoratorProps(
        baseStyle: const TextStyle(fontSize: 13, height: 1.0),
        decoration: InputDecoration(
          constraints: const BoxConstraints(maxHeight: 42),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 10,
          ),
          labelStyle: const TextStyle(fontSize: 12),
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          autofocus: true,
          style: TextStyle(fontSize: 13, height: 1.0),
          decoration: InputDecoration(
            constraints: BoxConstraints(maxHeight: 42),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            hintStyle: TextStyle(fontSize: 13, height: 1.0),
            hintText: "Cari...",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        itemBuilder: (context, item, isSelected, isDisabled) {
          final hasSut = item.data != null && item.data!['nomor_sut'] != null && item.data!['nomor_sut'].toString().isNotEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }
}
