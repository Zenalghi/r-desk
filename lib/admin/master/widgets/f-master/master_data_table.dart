// File: lib/admin/master/widgets/master_data_table.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'master_data_datasource.dart';

class MasterDataTable extends ConsumerStatefulWidget {
  const MasterDataTable({super.key});

  @override
  ConsumerState<MasterDataTable> createState() => _MasterDataTableState();
}

class _MasterDataTableState extends ConsumerState<MasterDataTable> {
  int _sortColumnIndex = 6;
  bool _sortAscending = false;
  int _rowsPerPage = 50;

  late final MasterDataDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = MasterDataDataSource(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(masterDataFilterProvider, (_, __) {
      // PERBAIKAN UTAMA: Gunakan addPostFrameCallback alih-alih Future.microtask
      // Ini menjamin tabel tidak di-refresh saat sedang me-layout panah sorting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dataSource.refreshDatasource();
        }
      });
    });

    return AsyncPaginatedDataTable2(
      columnSpacing: 3,
      horizontalMargin: 10,
      minWidth: 900,
      headingRowHeight: 35,
      dataRowHeight: 30,
      loading: const Center(child: CircularProgressIndicator()),
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
      source: _dataSource,
      empty: const Center(child: Text('Tidak ada data ditemukan')),
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
      6: 'created_at',
      7: 'updated_at',
    };

    ref
        .read(masterDataFilterProvider.notifier)
        .update(
          (state) => {
            ...state,
            'sortBy': columnMapping[columnIndex] ?? 'id',
            'sortDirection': ascending ? 'asc' : 'desc',
          },
        );
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
        label: const Text('Jenis Kendaraan'),
        size: ColumnSize.M,
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
      const DataColumn2(label: Text('Options'), fixedWidth: 123),
      const DataColumn2(
        label: Center(child: Text('Kelistrikan (Deskripsi)')),
        fixedWidth: 226,
      ),
    ];
  }
}
