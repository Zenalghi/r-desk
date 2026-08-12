//lib/admin/management/widgets/customer/customer_data_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customer_providers.dart';
import 'customer_data_source.dart';

class CustomerDataTable extends ConsumerStatefulWidget {
  const CustomerDataTable({super.key});

  @override
  ConsumerState<CustomerDataTable> createState() => _CustomerDataTableState();
}

class _CustomerDataTableState extends ConsumerState<CustomerDataTable> {
  int _rowsPerPage = 50;
  int _currentPage = 1;
  String _sortBy = 'nama_pt'; // Default sort pada kolom Customer (nama_pt)
  bool _sortAscending = true; // Ascending (A-Z)
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData({bool showLoading = false}) async {
    final searchQuery = ref.read(customerSearchQueryProvider);

    if (showLoading) {
      setState(() => _isRefreshing = true);
    }

    final start = DateTime.now();
    await ref
        .read(customerNotifierProvider.notifier)
        .getCustomers(
          page: _currentPage,
          rowsPerPage: _rowsPerPage,
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          searchQuery: searchQuery,
        );

    if (showLoading) {
      final elapsed = DateTime.now().difference(start);
      final remaining = const Duration(milliseconds: 500) - elapsed;
      if (remaining.isNegative) {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
        return;
      }

      await Future.delayed(remaining);
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(customerSearchQueryProvider, (previous, next) {
      if (previous != next) {
        _currentPage = 1;
        _fetchData();
      }
    });

    ref.listen<int>(customerInvalidator, (previous, next) {
      if (previous != next) {
        _fetchData(showLoading: true);
      }
    });

    final state = ref.watch(customerNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // PERBARUI CARA MEMBUAT DATA SOURCE
    final dataSource = CustomerDataSource(
      customers: state.customers,
      totalRecords: state.totalRecords,
      rowsPerPage: _rowsPerPage,
      currentPage: _currentPage,
      context: context,
      ref: ref,
    );

    return Stack(
      children: [
        Card(
          color: colorScheme.surface,
          child: PaginatedDataTable2(
            headingRowHeight: 36,
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 900,
            rowsPerPage: _rowsPerPage,

            // PERMINTAAN ANDA
            availableRowsPerPage: const [50, 100],

            onRowsPerPageChanged: (value) {
              if (value != null) {
                setState(() {
                  _rowsPerPage = value;
                  _currentPage = 1;
                });
                _fetchData();
              }
            },
            sortColumnIndex: _getSortColumnIndex(),
            sortAscending: _sortAscending,

            // HAPUS BARIS INI KARENA INI YANG MENYEBABKAN ERROR
            // total: state.totalRecords,
            initialFirstRowIndex: (_currentPage - 1) * _rowsPerPage,
            onPageChanged: (pageIndex) {
              int newPage = (pageIndex / _rowsPerPage).floor() + 1;
              if (newPage != _currentPage) {
                setState(() {
                  _currentPage = newPage;
                });
                _fetchData();
              }
            },
            empty: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : (state.error != null
                      ? Center(child: Text('Error: ${state.error}'))
                      : const Center(child: Text('Tidak ada data'))),
            columns: _createColumns(),
            source: dataSource,
          ),
        ),
        if (_isRefreshing)
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surface.withValues(alpha: 0.88),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }

  int _getSortColumnIndex() {
    switch (_sortBy) {
      case 'nama_pt':
        return 0;
      case 'pj':
        return 1;
      case 'jabatan':
        return 2;
      case 'drafter':
        return 3;
      case 'pemeriksa':
        return 4;
      case 'created_at':
        return 8;
      case 'updated_at':
        return 9;
      case 'status_tdp':
      case 'tdp_masa_berlaku':
        return 10;
      default:
        return 0;
    }
  }

  List<DataColumn2> _createColumns() {
    return [
      DataColumn2(
        label: const Text('Customer'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Penanggung Jawab'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Jabatan'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Drafter'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Pemeriksa'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),
      const DataColumn2(
        label: Text('Paraf PJ'),
        size: ColumnSize.S,
        onSort: null,
      ),
      const DataColumn2(
        label: Text('Paraf Drafter'),
        size: ColumnSize.S,
        onSort: null,
      ),
      const DataColumn2(
        label: Text('Paraf Pemeriksa'),
        size: ColumnSize.S,
        onSort: null,
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
      DataColumn2(
        label: const Text('Status TDP'),
        fixedWidth: 90,
        onSort: _onSort,
      ),
      const DataColumn2(label: Text('Option'), fixedWidth: 87, onSort: null),
    ];
  }

  void _onSort(int columnIndex, bool ascending) {
    String newSortBy;
    switch (columnIndex) {
      case 0:
        newSortBy = 'nama_pt';
        break;
      case 1:
        newSortBy = 'pj';
        break;
      case 2:
        newSortBy = 'jabatan';
        break;
      case 3:
        newSortBy = 'drafter';
        break;
      case 4:
        newSortBy = 'pemeriksa';
        break;
      case 8:
        newSortBy = 'created_at';
        break;
      case 9:
        newSortBy = 'updated_at';
        break;
      case 10:
        newSortBy = 'status_tdp';
        break;
      default:
        return;
    }
    setState(() {
      _sortBy = newSortBy;
      _sortAscending = ascending;
    });
    _fetchData();
  }
}
