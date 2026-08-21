// File: lib/admin/master/widgets/gambar_optional_table.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'gambar_optional_datasource.dart';

class GambarOptionalTable extends ConsumerStatefulWidget {
  const GambarOptionalTable({super.key});

  @override
  ConsumerState<GambarOptionalTable> createState() =>
      _GambarOptionalTableState();
}

class _GambarOptionalTableState extends ConsumerState<GambarOptionalTable> {
  int _sortColumnIndex = 7; // Default: updated_at (sesuaikan index kolom baru)
  bool _sortAscending = false;
  int _rowsPerPage = 50;

  @override
  Widget build(BuildContext context) {
    final dataSource = GambarOptionalDataSource(ref, context);

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
      empty: const Center(
        child: Text('Tidak ada data Gambar Optional Independen'),
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    // Mapping Index Kolom -> Field Backend
    final Map<int, String> columnMapping = {
      0: 'id',
      1: 'type_engine',
      2: 'merk',
      3: 'type_chassis',
      4: 'nomor_sut',
      5: 'jenis_kendaraan',
      6: 'deskripsi_optional',
      7: 'created_at',
      8: 'updated_at',
    };

    ref.read(gambarOptionalFilterProvider.notifier).update((state) {
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
      DataColumn2(
        label: const Text('Merk'),
        size: ColumnSize.S,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Type Chassis'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Nomor SUT'),
        size: ColumnSize.S,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Jenis Kendaraan'),
        size: ColumnSize.S,
        onSort: _onSort,
      ),
      // HAPUS VARIAN BODY & TIPE
      DataColumn2(
        label: const Text('Deskripsi'),
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
      const DataColumn2(label: Text('Options'), fixedWidth: 165),
    ];
  }
}
