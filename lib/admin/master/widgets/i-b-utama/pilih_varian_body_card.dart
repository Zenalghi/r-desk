// File: lib/admin/master/widgets/pilih_varian_body_card.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/app/core/providers.dart';

class PilihVarianBodyCard extends ConsumerStatefulWidget {
  final bool isEditMode;
  const PilihVarianBodyCard({super.key, this.isEditMode = false});

  @override
  ConsumerState<PilihVarianBodyCard> createState() =>
      _PilihVarianBodyCardState();
}

class _PilihVarianBodyCardState extends ConsumerState<PilihVarianBodyCard>
    with AutomaticKeepAliveClientMixin {
  OptionItem? _selectedMasterData;
  OptionItem? _selectedVarianBody;
  int _dropdownSeed = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadInitialData();
    });
  }

  void _checkAndLoadInitialData() {
    final pendingData = ref.read(initialGambarUtamaDataProvider);
    if (pendingData != null) {
      _processInitialData(pendingData);
    }
  }

  void _processInitialData(Map<String, dynamic> data) {
    final masterDataItem = data['masterData'] as OptionItem;
    final varianBodyItem = data['varianBody'] as OptionItem;

    setState(() {
      _selectedMasterData = masterDataItem;
      _selectedVarianBody = varianBodyItem;
      _dropdownSeed++; // Force rebuild dropdown dengan key baru agar value ter-update visualnya
    });

    // Update Provider ID agar logika aplikasi lain berjalan
    ref.read(mguSelectedMasterDataIdProvider.notifier).state =
        masterDataItem.id as int;
    ref.read(mguSelectedVarianBodyIdProvider.notifier).state =
        varianBodyItem.id as int;
    ref.read(mguSelectedVarianBodyNameProvider.notifier).state =
        varianBodyItem.name;

    // Bersihkan data inisial agar tidak diproses ulang sembarangan
    // ref.read(initialGambarUtamaDataProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 1. Listener untuk Data Awal
    ref.listen<Map<String, dynamic>?>(initialGambarUtamaDataProvider, (
      prev,
      next,
    ) {
      if (next != null) {
        _processInitialData(next);
      } else {
        // Ini menangani reset jika trigger datang dari initialDataProvider
        setState(() {
          _selectedMasterData = null;
          _selectedVarianBody = null;
          _dropdownSeed++;
        });
      }
    });

    // 2. PERBAIKAN: Listener untuk Provider ID Global (Menangani Reset Manual)
    // Jika ID di provider global jadi null (karena _resetForm dipanggil),
    // maka kita wajib membersihkan dropdown lokal.
    ref.listen<int?>(mguSelectedMasterDataIdProvider, (prev, next) {
      if (next == null && _selectedMasterData != null) {
        setState(() {
          _selectedMasterData = null;
          _selectedVarianBody = null;
          _dropdownSeed++; // Paksa rebuild dropdown agar teks kembali ke labelText
        });
      }
    });

    final globalSelectedMasterId = ref.watch(mguSelectedMasterDataIdProvider);

    return Card(
      // Bungkus dengan IgnorePointer jika Mode Edit aktif
      child: IgnorePointer(
        ignoring: widget.isEditMode,
        child: Opacity(
          opacity: widget.isEditMode ? 0.6 : 1.0, // Redupkan jika disabled
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "1. Pilih Data Kendaraan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.isEditMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Mode Edit (Terkunci)",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),

                // 1. DROPDOWN MASTER DATA
                DropdownSearch<OptionItem>(
                  key: ValueKey('master_$_dropdownSeed'),
                  items: (String filter, _) => ref
                      .read(masterDataRepositoryProvider)
                      .getMasterDataOptions(filter),
                  itemAsString: (item) => item.name,
                  compareFn: (item1, item2) => item1.id == item2.id,
                  selectedItem: _selectedMasterData,
                  onChanged: (OptionItem? item) {
                    setState(() {
                      _selectedMasterData = item;
                      if (item?.id != globalSelectedMasterId) {
                        _selectedVarianBody = null;
                      }
                    });

                    ref.read(mguSelectedMasterDataIdProvider.notifier).state =
                        item?.id as int?;

                    if (item?.id != globalSelectedMasterId) {
                      ref.read(mguSelectedVarianBodyIdProvider.notifier).state =
                          null;
                      ref
                              .read(mguSelectedVarianBodyNameProvider.notifier)
                              .state =
                          null;
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
                      labelText:
                          'Pilih Master Data (Engine / Merk / Chassis / Jenis)',
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
                ),

                const SizedBox(height: 8),

                // 2. DROPDOWN VARIAN BODY
                DropdownSearch<OptionItem>(
                  key: ValueKey('varian_$_dropdownSeed'),
                  enabled: globalSelectedMasterId != null,
                  items: (String filter, _) async {
                    if (globalSelectedMasterId == null) return [];
                    final response = await ref
                        .read(apiClientProvider)
                        .dio
                        .get(
                          '/admin/varian-body',
                          queryParameters: {
                            'search': filter,
                            'master_data_id': globalSelectedMasterId,
                          },
                        );
                    final List data = response.data['data'];
                    return data
                        .map(
                          (e) =>
                              OptionItem(id: e['id'], name: e['varian_body']),
                        )
                        .toList();
                  },
                  itemAsString: (item) => item.name,
                  compareFn: (item1, item2) => item1.id == item2.id,
                  selectedItem: _selectedVarianBody,
                  onChanged: (OptionItem? item) {
                    setState(() {
                      _selectedVarianBody = item;
                    });

                    ref.read(mguSelectedVarianBodyIdProvider.notifier).state =
                        item?.id as int?;
                    ref.read(mguSelectedVarianBodyNameProvider.notifier).state =
                        item?.name;
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
                      labelText: 'Pilih Varian Body',
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
                        hintText: "Cari Varian...",
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
