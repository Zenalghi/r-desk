// File: lib/admin/master/widgets/varian_body_table.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'varian_body_datasource.dart';

class VarianBodyTable extends ConsumerStatefulWidget {
  const VarianBodyTable({super.key});

  @override
  ConsumerState<VarianBodyTable> createState() => _VarianBodyTableState();
}

class _VarianBodyTableState extends ConsumerState<VarianBodyTable> {
  int _sortColumnIndex = 6; // Default: updated_at
  bool _sortAscending = false; // Default: desc
  int _rowsPerPage = 50;

  @override
  Widget build(BuildContext context) {
    final selectedMasterDataId = ref.watch(selectedMasterDataFilterProvider);
    // Buat DataSource di dalam build agar mendapatkan ref yang benar
    final dataSource = VarianBodyDataSource(ref, context);

    return AsyncPaginatedDataTable2(
      columnSpacing: 3,
      horizontalMargin: 10,
      minWidth: 900,
      headingRowHeight: 35,
      dataRowHeight: 30,
      rowsPerPage: _rowsPerPage,
      availableRowsPerPage: const [50, 100],
      onRowsPerPageChanged: (value) {
        if (value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _rowsPerPage = value;
            });
          });
        }
      },
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: _createColumns(),
      source: dataSource,
      loading: const Center(child: CircularProgressIndicator()),
      empty: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedMasterDataId != null ? Icons.info_outline : Icons.search,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              selectedMasterDataId != null
                  ? 'Varian Body belum ditambahkan pada Master Data ini.\nSilakan isi nama varian di atas dan tekan Tambah.'
                  : 'Pilih Master Data di atas untuk memfilter, atau cari menggunakan Search.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    final Map<int, String> columnMapping = {
      0: 'id',
      1: 'type_engine',
      2: 'merk',
      3: 'type_chassis',
      4: 'nomor_sut',
      5: 'jenis_kendaraan',
      6: 'varian_body',
      7: 'created_at',
      8: 'updated_at',
    };

    ref.read(varianBodyFilterProvider.notifier).update((state) {
      return {
        ...state,
        'sortBy': columnMapping[columnIndex] ?? 'updated_at',
        'sortDirection': ascending ? 'asc' : 'desc',
      };
    });
  }

  List<DataColumn2> _createColumns() {
    return [
      DataColumn2(label: const Text('ID'), fixedWidth: 40, onSort: _onSort),
      DataColumn2(
        label: const Text('Type\nEngine'),
        fixedWidth: 62,
        onSort: _onSort,
      ),
      DataColumn2(label: const Text('Merk'), fixedWidth: 110, onSort: _onSort),
      DataColumn2(
        label: const Text('Type Chassis'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Nomor SUT'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Jenis\nKendaraan'),
        size: ColumnSize.S,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Varian Body'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Created At'),
        fixedWidth: 115,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Updated At'),
        fixedWidth: 115,
        onSort: _onSort,
      ),
      const DataColumn2(label: Text('Options'), fixedWidth: 93),
    ];
  }
}
