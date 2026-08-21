import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:master_gambar/admin/master/models/master_data.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';

class AddMasterDataForm extends ConsumerStatefulWidget {
  const AddMasterDataForm({super.key});

  @override
  ConsumerState<AddMasterDataForm> createState() => _AddMasterDataFormState();
}

class _AddMasterDataFormState extends ConsumerState<AddMasterDataForm> {
  final _formKey = GlobalKey<FormState>();

  OptionItem? _selectedTypeEngine;
  OptionItem? _selectedMerk;
  OptionItem? _selectedTypeChassis;
  OptionItem? _selectedJenisKendaraan;

  @override
  Widget build(BuildContext context) {
    ref.listen<MasterData?>(masterDataToCopyProvider, (prev, next) {
      if (next != null) {
        setState(() {
          _selectedTypeEngine = OptionItem(
            id: next.typeEngine.id,
            name: next.typeEngine.name,
          );
          _selectedMerk = OptionItem(id: next.merk.id, name: next.merk.name);
          _selectedTypeChassis = OptionItem(
            id: next.typeChassis.id,
            name: next.typeChassis.displayName,
          );
          _selectedJenisKendaraan = OptionItem(
            id: next.jenisKendaraan.id,
            name: next.jenisKendaraan.name,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data disalin! Silakan ubah field yang diperlukan.'),
            backgroundColor: Colors.blue,
          ),
        );
        ref.read(masterDataToCopyProvider.notifier).state = null;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchableDropdown(
                label: 'Type Engine',
                provider: mdTypeEngineOptionsProvider,
                selectedItem: _selectedTypeEngine,
                onChanged: (val) => _selectedTypeEngine = val,
              ),
              const SizedBox(width: 16),
              _buildSearchableDropdown(
                label: 'Merk',
                provider: mdMerkOptionsProvider,
                selectedItem: _selectedMerk,
                onChanged: (val) => _selectedMerk = val,
              ),
              const SizedBox(width: 16),
              _buildSearchableDropdown(
                label: 'Type Chassis',
                provider: mdTypeChassisOptionsProvider,
                selectedItem: _selectedTypeChassis,
                onChanged: (val) => _selectedTypeChassis = val,
              ),
              const SizedBox(width: 16),
              _buildSearchableDropdown(
                label: 'Jenis Kendaraan',
                provider: mdJenisKendaraanOptionsProvider,
                selectedItem: _selectedJenisKendaraan,
                onChanged: (val) => _selectedJenisKendaraan = val,
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(masterDataRepositoryProvider)
          .addMasterData(
            typeEngineId: _selectedTypeEngine!.id as int,
            merkId: _selectedMerk!.id as int,
            typeChassisId: _selectedTypeChassis!.id as int,
            jenisKendaraanId: _selectedJenisKendaraan!.id as int,
          );

      ref
          .read(masterDataFilterProvider.notifier)
          .update(
            (state) => {
              ...state,
              'last_update': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            //durasi 1 detik
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan pada server';

        // Cek apakah ini error validasi (422)
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];
          if (errors != null) {
            // Ambil pesan error pertama yang ditemukan
            // Prioritaskan pesan duplicate dari jenis kendaraan
            if (errors['d_jenis_kendaraan_id'] != null) {
              errorMessage = errors['d_jenis_kendaraan_id'][0];
            } else {
              // Atau ambil error apapun yang pertama muncul
              errorMessage = errors.values.first[0];
            }
          } else {
            errorMessage = e.response?.data['message'] ?? errorMessage;
          }
        } else {
          // Error server lain (500, dll)
          errorMessage = 'Error: ${e.response?.data['message'] ?? e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(
              seconds: 2,
            ), // Beri waktu lebih lama buat baca
          ),
        );
      }
    }
  }

  Widget _buildSearchableDropdown({
    required String label,
    required FutureProviderFamily<List<OptionItem>, String> provider,
    required OptionItem? selectedItem,
    required Function(OptionItem?) onChanged,
  }) {
    return Expanded(
      child: DropdownSearch<OptionItem>(
        items: (String filter, _) => ref.read(provider(filter).future),
        itemAsString: (OptionItem item) => item.name,
        compareFn: (item1, item2) => item1.id == item2.id,
        selectedItem: selectedItem, // <-- Gunakan state lokal
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
      ),
    );
  }
}
