// File: lib/admin/master/widgets/master_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/elements/auth/presentation/auth_provider.dart';

class MasterSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const MasterSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);

    // Tentukan lebar sidebar
    return SizedBox(
      width: 160,
      // Gunakan Drawer untuk mendapatkan style latar belakang dan elevasi yang konsisten
      child: Drawer(
        elevation: 0,
        backgroundColor: Theme.of(context).canvasColor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // --- KATEGORI 1: MASTER DATA ---
                  ExpansionTile(
                    title: const Text(
                      'Master Data',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    initiallyExpanded: true, // Default expand sesuai permintaan
                    childrenPadding: const EdgeInsets.only(left: 6.0),
                    children: [
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.dns, size: 21),
                        title: const Text(
                          'Type Engine',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 0,
                        onTap: () => onItemSelected(0),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.bookmark, size: 21),
                        title: const Text('Merk', style: TextStyle(fontSize: 11)),
                        selected: selectedIndex == 1,
                        onTap: () => onItemSelected(1),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.fire_truck_rounded, size: 21),
                        title: const Text(
                          'Type Chassis',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 2,
                        onTap: () => onItemSelected(2),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.directions_car_outlined, size: 21),
                        title: const Text(
                          'Jenis Kendaraan',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 3,
                        onTap: () => onItemSelected(3),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.category_outlined, size: 21),
                        title: const Text(
                          'Master Varian\nBody',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 4,
                        onTap: () => onItemSelected(4),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.dataset_linked_rounded, size: 21),
                        title: const Text(
                          'Master Data',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 5,
                        onTap: () => onItemSelected(5),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.category_sharp, size: 21),
                        title: const Text(
                          'Varian Body',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 6,
                        onTap: () => onItemSelected(6),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.title_outlined, size: 21),
                        title: const Text(
                          'Jenis Varian',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 7,
                        onTap: () => onItemSelected(7),
                      ),
                    ],
                  ),

                  const Divider(),

                  // --- KATEGORI 2: MASTER GAMBAR ---
                  ExpansionTile(
                    title: const Text(
                      'Master Gambar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    initiallyExpanded: true, // Default expand sesuai permintaan
                    childrenPadding: const EdgeInsets.only(left: 6.0),
                    children: [
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.inventory_2_outlined, size: 21),
                        title: const Text(
                          'Laporan Status Gambar',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 8,
                        onTap: () => onItemSelected(8),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(Icons.image_outlined, size: 21),
                        title: const Text(
                          'Gambar Utama',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 9,
                        onTap: () => onItemSelected(9),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 21,
                        ),
                        title: const Text(
                          'Gambar Optional',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 10,
                        onTap: () => onItemSelected(10),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minLeadingWidth: 22,
                        leading: const Icon(
                          Icons.electrical_services_outlined,
                          size: 21,
                        ),
                        title: const Text(
                          'Gambar Kelistrikan',
                          style: TextStyle(fontSize: 11),
                        ),
                        selected: selectedIndex == 11,
                        onTap: () => onItemSelected(11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: versionAsync.when(
                data: (packageInfo) => Text(
                  'v${packageInfo.version}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
