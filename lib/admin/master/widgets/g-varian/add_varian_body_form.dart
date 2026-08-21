// lib/admin/master/widgets/add_varian_body_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dio/dio.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/app/core/providers.dart';

class AddVarianBodyForm extends ConsumerStatefulWidget {
  const AddVarianBodyForm({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  ConsumerState<AddVarianBodyForm> createState() => _AddVarianBodyFormState();
}

class _AddVarianBodyFormState extends ConsumerState<AddVarianBodyForm> {
  final _formKey = GlobalKey<FormState>();
  List<OptionItem> _selectedMasterVarians = []; // Untuk multi-select
  bool _isLoading = false;

  @override
  void didUpdateWidget(covariant AddVarianBodyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(() => _selectedMasterVarians = []);
    }
  }

  // --- FUNGSI BARU: Ambil Data Existing dari Database ---
  Future<void> _fetchExistingVarians(int masterDataId) async {
    setState(() => _isLoading = true);
    try {
      // Panggil endpoint /options/varian-body/{masterDataId} untuk mengambil list Varian Body yang sudah tersimpan
      final response = await ref
          .read(apiClientProvider)
          .dio
          .get('/options/varian-body/$masterDataId');

      final List<dynamic> data = response.data;

      // Mapping respon menjadi OptionItem agar bisa dibaca oleh DropdownSearch
      final existingVarians = data.map((e) => OptionItem.fromJson(e)).toList();

      setState(() {
        _selectedMasterVarians = existingVarians;
      });
    } catch (e) {
      debugPrint('Error fetching existing varians: $e');
      setState(() => _selectedMasterVarians = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedMasterData = ref.read(selectedMasterDataFilterProvider);
    if (selectedMasterData == null || _selectedMasterVarians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih Master Data dan minimal 1 Varian!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final List<String> varianBodies = _selectedMasterVarians
          .map((e) => e.name)
          .toList();

      final result = await ref
          .read(masterDataRepositoryProvider)
          .addVarianBody(
            masterDataId: selectedMasterData.id,
            varianBodies: varianBodies,
          );

      // Setelah simpan, refresh datanya (agar state tetap relevan dengan DB terbaru)
      await _fetchExistingVarians(selectedMasterData.id);

      ref
          .read(varianBodyFilterProvider.notifier)
          .update((state) => Map.from(state));

      if (!mounted) return;

      if (result.skipped.isNotEmpty) {
        final skippedText = result.skipped.join(', ');
        final createdText = result.created.isNotEmpty
            ? ' ${result.created.length} varian baru berhasil disimpan. '
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${createdText}Data sudah ada: $skippedText.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: result.created.isNotEmpty
                ? const Color.fromARGB(255, 50, 174, 223)
                : const Color.fromARGB(255, 163, 122, 0),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Varian Body berhasil ditambahkan!'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMasterData = ref.watch(selectedMasterDataFilterProvider);

    final int? jkId = selectedMasterData != null
        ? int.tryParse(
            selectedMasterData.data?['d_jenis_kendaraan_id']?.toString() ?? '',
          )
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dropdown Master Data
              Expanded(
                flex: 2,
                child: DropdownSearch<OptionItem>(
                  items: (String filter, _) =>
                      ref.read(masterDataOptionsProvider(filter).future),
                  itemAsString: (OptionItem item) => item.name,
                  compareFn: (item1, item2) => item1.id == item2.id,
                  selectedItem: selectedMasterData,
                  // --- PERUBAHAN: onChanged menjadi async ---
                  onChanged: (OptionItem? item) async {
                    ref.read(selectedMasterDataFilterProvider.notifier).state =
                        item;
                    if (item != null) {
                      // Panggil API untuk nge-set checkbox yang sudah ada
                      await _fetchExistingVarians(item.id as int);
                    } else {
                      setState(() => _selectedMasterVarians = []);
                    }
                  },
                  decoratorProps: const DropDownDecoratorProps(
                    baseStyle: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      labelStyle: TextStyle(fontSize: 12),
                      labelText:
                          'Pilih Master Data (Engine / Merk / Chassis / Jenis)',
                      hintText: 'Ketik untuk mencari...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      autofocus: true,
                      style: TextStyle(fontSize: 13, height: 1.0),
                      decoration: InputDecoration(
                        constraints: BoxConstraints(maxHeight: 32),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        hintStyle: TextStyle(fontSize: 13, height: 1.0),
                        hintText: "Cari (contoh: Hino, Box, dll)...",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    menuProps: const MenuProps(
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
                      item == null && selectedMasterData == null
                      ? 'Wajib dipilih'
                      : null,
                ),
              ),

              const SizedBox(width: 16),

              // 2. Dropdown Checkbox Master Varian
              Expanded(
                flex: 3,
                child: Builder(
                  builder: (context) {
                    return DropdownSearch<OptionItem>.multiSelection(
                      enabled: selectedMasterData != null,
                      items: (String filter, _) async {
                        if (jkId == null) return [];
                        return await ref.read(
                          masterVarianOptionsFamilyProvider(jkId).future,
                        );
                      },
                      itemAsString: (OptionItem item) => item.name,

                      // --- PERUBAHAN KRUSIAL ---
                      // Karena ID dari Master Varian (kamus) dan Varian Body (tersimpan) berbeda,
                      // Kita bandingkan berdasarkan NAMA (teksnya) dengan Uppercase agar seragam.
                      compareFn: (item1, item2) =>
                          item1.name.toUpperCase() == item2.name.toUpperCase(),

                      // -------------------------
                      selectedItems: _selectedMasterVarians,
                      onChanged: (List<OptionItem> items) {
                        setState(() => _selectedMasterVarians = items);
                      },
                      selectedItemsScrollProps: const ScrollProps(
                        physics: BouncingScrollPhysics(),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        baseStyle: TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          labelStyle: TextStyle(fontSize: 12),
                          labelText: 'Pilih Varian Body',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                        checkBoxBuilder:
                            (context, item, isDisabled, isSelected) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: isDisabled ? null : (_) {},
                                ),
                              );
                            },
                        searchFieldProps: const TextFieldProps(
                          autofocus: true,
                          style: TextStyle(fontSize: 13, height: 1.0),
                          decoration: InputDecoration(
                            constraints: BoxConstraints(maxHeight: 32),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            hintStyle: TextStyle(fontSize: 13, height: 1.0),
                            hintText: "Cari varian...",
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        menuProps: const MenuProps(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        itemBuilder: (context, item, isSelected, isDisabled) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
                            height: 30,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.0,
                                      color: isDisabled
                                          ? Colors.grey
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      validator: (items) => (items == null || items.isEmpty)
                          ? 'Wajib pilih varian'
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // 3. Tombol Tambah
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Simpan Pilihan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
