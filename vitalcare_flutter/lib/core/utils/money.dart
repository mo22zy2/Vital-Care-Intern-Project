import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(symbol: 'E£');

String money(Object? value) {
  final n = value is num ? value : double.tryParse(value?.toString() ?? '');
  return _fmt.format(n ?? 0);
}
