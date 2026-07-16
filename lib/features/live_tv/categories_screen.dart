import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'live_tv_provider.dart';

/// Horizontal scrollable category selector.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveTvProvider);

    if (state.loading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final categories = state.categories;
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedId = state.selectedCategoryId;

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedId == null;
            return _CategoryChip(
              label: 'Todos',
              isSelected: isSelected,
              onTap: () => ref.read(liveTvProvider.notifier).selectCategory(null),
            );
          }
          final cat = categories[index - 1];
          final isSelected = selectedId == cat.categoryId;
          return _CategoryChip(
            label: cat.name,
            isSelected: isSelected,
            onTap: () =>
                ref.read(liveTvProvider.notifier).selectCategory(cat.categoryId),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
