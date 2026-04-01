import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/providers/spool_providers.dart';
import 'package:spooler_tag/ui/home/widgets/filament_form.dart';
import 'package:spooler_tag/ui/home/widgets/spool_dropdown.dart';
import 'package:spooler_tag/ui/home/widgets/status_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorHex = ref.watch(spoolFormProvider.select((s) => s.colorHex));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpoolerTag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(spoolListProvider);
                // Wait for the refresh to complete
                await ref.read(spoolListProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _SpoolLogo(colorHex: colorHex),
                    const SpoolDropdown(),
                    const FilamentForm(),
                  ],
                ),
              ),
            ),
          ),
          const StatusBar(),
        ],
      ),
    );
  }
}

class _SpoolLogo extends StatelessWidget {
  final String? colorHex;

  const _SpoolLogo({this.colorHex});

  @override
  Widget build(BuildContext context) {
    final color = colorHex != null && colorHex!.length == 6
        ? Color(int.parse('FF$colorHex', radix: 16))
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Icon(
        Icons.circle,
        size: 64,
        color: color,
      ),
    );
  }
}
