import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/elements/auth/presentation/auth_provider.dart';

class ConfigurationSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ConfigurationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Customer'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                label: Text('Document'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('User'),
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
    );
  }
}
