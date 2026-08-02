import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctl.text = widget.initialQuery;
    if (_ctl.text.isNotEmpty) _search();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctl.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('${ApiConstants.search}?q=$q');
      setState(() {
        _results = (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _ctl,
                  decoration: InputDecoration(
                    hintText: 'Search doctors, medicines, lab tests...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _ctl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _ctl.clear(); setState(() => _results = []); })
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20)),
                  child: const Text('Search', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'No results', description: 'Try a different search term')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            onTap: () => _navigate(r),
                            leading: AppBadge(label: r['type']?.toString() ?? ''),
                            title: Text(r['label']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _navigate(Map<String, dynamic> r) {
    final type = r['type']?.toString() ?? '';
    final id = r['id']?.toString() ?? '';
    final extra = r;
    switch (type) {
      case 'doctor':
        context.push('/doctors/$id', extra: extra);
      case 'medicine':
        context.push('/pharmacy');
      case 'lab_test':
        context.push('/laboratory');
      case 'invoice':
        context.push('/billing');
      default:
        context.push('/search', extra: _ctl.text);
    }
  }
}
