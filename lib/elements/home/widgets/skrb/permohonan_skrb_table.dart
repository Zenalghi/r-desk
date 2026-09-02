// File: lib/elements/home/widgets/skrb/permohonan_skrb_table.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../providers/skrb_providers.dart';
import 'permohonan_skrb_datasource.dart';

class PermohonanSkrbTable extends ConsumerStatefulWidget {
  const PermohonanSkrbTable({super.key});

  @override
  ConsumerState<PermohonanSkrbTable> createState() =>
      _PermohonanSkrbTableState();
}

class _PermohonanSkrbTableState extends ConsumerState<PermohonanSkrbTable> {
  int _rowsPerPage = 50;
  int? _sortColumnIndex = 8;
  bool _sortAscending = false;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skrbListAsync = ref.watch(filteredSkrbListProvider);

    return skrbListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text('Gagal memuat data SKRB:\n$err', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(skrbListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (skrbList) {
        if (skrbList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(102),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada riwayat Permohonan SKRB.\nSilahkan buat baru menggunakan Dropdown di atas atau sesuaikan filter Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final sortedList = List.of(skrbList);
        if (_sortColumnIndex != null) {
          sortedList.sort((a, b) {
            int cmp = 0;
            switch (_sortColumnIndex) {
              case 0:
                cmp = a.idSkrb.compareTo(b.idSkrb);
                break;
              case 1:
                cmp = a.transaksiId.compareTo(b.transaksiId);
                break;
              case 2:
                cmp = a.customerName.compareTo(b.customerName);
                break;
              case 3:
                cmp = a.typeEngine.compareTo(b.typeEngine);
                break;
              case 4:
                cmp = a.merk.compareTo(b.merk);
                break;
              case 5:
                cmp = a.chassisDisplayName.compareTo(b.chassisDisplayName);
                break;
              case 6:
                cmp = a.jenisKendaraan.compareTo(b.jenisKendaraan);
                break;
              case 7:
                cmp = a.jenisPengajuan.compareTo(b.jenisPengajuan);
                break;
              case 8:
                cmp = a.createdAt.compareTo(b.createdAt);
                break;
              case 9:
                cmp = a.updatedAt.compareTo(b.updatedAt);
                break;
              case 10:
                cmp = a.statusTdp.compareTo(b.statusTdp);
                if (cmp == 0) {
                  cmp = (a.tdpMasaBerlaku ?? '').compareTo(
                    b.tdpMasaBerlaku ?? '',
                  );
                }
                break;
            }
            return _sortAscending ? cmp : -cmp;
          });
        }

        final bool isRefreshing =
            skrbListAsync.isRefreshing || skrbListAsync.isLoading;
        final dataSource = PermohonanSkrbDataSource(
          skrbList: sortedList,
          ref: ref,
          context: context,
        );

        return Stack(
          children: [
            PaginatedDataTable2(
              columnSpacing: 10,
              horizontalMargin: 10,
              minWidth: 1200, // Menyesuaikan dengan monitor 1360x768
              headingRowHeight: 35,
              dataRowHeight: 30,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              rowsPerPage: _rowsPerPage > skrbList.length && skrbList.isNotEmpty
                  ? (skrbList.length > 50 ? 100 : 50)
                  : _rowsPerPage,
              availableRowsPerPage: const [50, 100],
              onRowsPerPageChanged: (value) {
                if (value != null) {
                  setState(() => _rowsPerPage = value);
                }
              },
              source: dataSource,
              columns: [
                DataColumn2(
                  label: const Text('ID SKRB'),
                  fixedWidth: 160,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('ID DWG'),
                  fixedWidth: 75,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Customer'),
                  size: ColumnSize.M,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Type\nEngine'),
                  fixedWidth: 68,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Merk'),
                  size: ColumnSize.S,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Type Chassis'),
                  size: ColumnSize.L,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Jenis\nKendaraan'),
                  size: ColumnSize.S,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Jenis\nPengajuan'),
                  size: ColumnSize.S,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Created at'),
                  fixedWidth: 110,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Updated at'),
                  fixedWidth: 110,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Status TDP'),
                  fixedWidth: 115,
                  onSort: _onSort,
                ),
                const DataColumn2(
                  label: Text('Options'),
                  fixedWidth: 133,
                  onSort: null,
                ),
              ],
            ),
            if (isRefreshing)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.black.withAlpha(15),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Memuat ulang tabel...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
