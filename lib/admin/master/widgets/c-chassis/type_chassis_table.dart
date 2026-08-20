import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_data_providers.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'type_chassis_datasource.dart';

class TypeChassisTable extends ConsumerStatefulWidget {
  const TypeChassisTable({super.key});

  @override
  ConsumerState<TypeChassisTable> createState() => _TypeChassisTableState();
}

class _TypeChassisTableState extends ConsumerState<TypeChassisTable> {
  int _sortColumnIndex = 0; // ID
  bool _sortAscending = true; // asc
  int _rowsPerPage = 50;

  @override
  Widget build(BuildContext context) {
    final dataSource = TypeChassisDataSource(ref, context);

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
      empty: const Center(child: Text('Tidak ada data ditemukan')),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    ref.read(typeChassisFilterProvider.notifier).update((state) {
      final Map<int, String> columnMapping = {
        0: 'id',
        1: 'type_chassis',
        2: 'nomor_sut',
        3: 'merek_dagang',
        4: 'jenis_tipe',
        5: 'created_at',
        6: 'updated_at',
      };
      return {
        ...state,
        'sortBy': columnMapping[columnIndex] ?? 'id',
        'sortDirection': ascending ? 'asc' : 'desc',
      };
    });
  }

  List<DataColumn2> _createColumns() {
    return [
      DataColumn2(label: const Text('ID'), fixedWidth: 40, onSort: _onSort),
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
        label: const Text('Merek Dagang'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Jenis Tipe'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Created At'),
        fixedWidth: 120,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Updated At'),
        fixedWidth: 120,
        onSort: _onSort,
      ),
      const DataColumn2(label: Text('Options'), fixedWidth: 280),
    ];
  }
}
