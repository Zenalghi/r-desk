// File: lib/admin/master/widgets/gambar_kelistrikan_table.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'gambar_kelistrikan_datasource.dart';

class GambarKelistrikanTable extends ConsumerStatefulWidget {
  const GambarKelistrikanTable({super.key});

  @override
  ConsumerState<GambarKelistrikanTable> createState() =>
      _GambarKelistrikanTableState();
}

class _GambarKelistrikanTableState
    extends ConsumerState<GambarKelistrikanTable> {
  // Default sort: Updated At (Index 5), Descending
  int _sortColumnIndex = 5;
  bool _sortAscending = false;
  int _rowsPerPage = 50;

  late final GambarKelistrikanDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    // 1. Buat DataSource SEKALI SAJA di sini
    _dataSource = GambarKelistrikanDataSource(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    // 2. PASANG LISTENER DI SINI (Di dalam build)
    ref.listen(gambarKelistrikanFilterProvider, (_, __) {
      _dataSource.refreshDatasource();
    });

    return AsyncPaginatedDataTable2(
      columnSpacing: 3,
      horizontalMargin: 10,
      minWidth: 900,
      headingRowHeight: 35,
      dataRowHeight: 30,
      // Pagination Config
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

      // Sorting Config
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,

      columns: _createColumns(),
      source: _dataSource,
      loading: const Center(child: CircularProgressIndicator()),
      empty: const Center(child: Text('Tidak ada data ditemukan')),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    // KEY MAP HARUS SAMA DENGAN VALIDASI BACKEND
    final Map<int, String> columnMapping = {
      0: 'id',
      1: 'type_engine', // Backend: 'type_engine' => 'a_type_engines.type_engine'
      2: 'merk', // Backend: 'merk' => 'b_merks.merk'
      3: 'type_chassis', // Backend: 'type_chassis' => 'c_type_chassis.type_chassis'
      4: 'nomor_sut',
      5: 'created_at',
      6: 'updated_at',
    };

    ref
        .read(gambarKelistrikanFilterProvider.notifier)
        .update(
          (state) => {
            ...state,
            'sortBy': columnMapping[columnIndex] ?? 'updated_at',
            'sortDirection': ascending ? 'asc' : 'desc',
          },
        );
  }

  List<DataColumn2> _createColumns() {
    return [
      DataColumn2(label: const Text('ID'), fixedWidth: 40, onSort: _onSort),
      DataColumn2(
        label: const Text('Type Engine'),
        size: ColumnSize.S,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Merk'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
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
        label: const Text('Created At'),
        fixedWidth: 115,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Updated At'),
        fixedWidth: 115,
        onSort: _onSort,
      ),
      const DataColumn2(label: Text('Options'), fixedWidth: 127),
    ];
  }
}
