import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppFilterBar extends StatelessWidget {
  final TextEditingController? searchController;
  final String? searchHint;
  final List<DropdownFilter>? filters;
  final VoidCallback? onFilter;

  const AppFilterBar({
    super.key,
    this.searchController,
    this.searchHint,
    this.filters,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (searchController != null)
            SizedBox(
              width: 220,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (filters != null)
            for (final f in filters!)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surface,
                    ),
                    child: DropdownButton<String>(
                      value: f.value,
                      hint: Text(f.hint, style: const TextStyle(fontSize: 13)),
                      items: f.items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: f.onChanged,
                      isDense: true,
                      underline: const SizedBox(),
                    ),
                  ),
                ),
              ),
          if (onFilter != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: onFilter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Filter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DropdownFilter {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const DropdownFilter({
    required this.hint,
    this.value,
    required this.items,
    this.onChanged,
  });
}
