import 'package:flutter_test/flutter_test.dart';
import 'package:vitalcare_flutter/core/network/api_client.dart';
import 'package:vitalcare_flutter/core/providers/base_provider.dart';

class _TestProvider extends BaseProvider {
  int loadCount = 0;

  Future<bool> succeed() => guard(() async => loadCount++);

  Future<bool> failWithApiError() => guard(() async => throw ApiException(500, 'Server exploded'));

  Future<bool> failWithGeneric() => guard(() async => throw StateError('boom'));

  Future<bool> failWithMessage() => guard(() async => throw StateError('boom'), errorMessage: 'Friendly message');

  List<Map<String, dynamic>> extract(dynamic res) => unwrapList(res);
}

void main() {
  test('guard sets loading, clears error, returns true on success', () async {
    final p = _TestProvider();
    expect(p.isLoading, isFalse);
    final ok = await p.succeed();
    expect(ok, isTrue);
    expect(p.error, isNull);
    expect(p.isLoading, isFalse);
    expect(p.loadCount, 1);
  });

  test('guard surfaces ApiException message', () async {
    final p = _TestProvider();
    final ok = await p.failWithApiError();
    expect(ok, isFalse);
    expect(p.error, 'Server exploded');
  });

  test('guard surfaces raw error text when no message given', () async {
    final p = _TestProvider();
    await p.failWithGeneric();
    expect(p.error, contains('boom'));
  });

  test('guard prefers friendly errorMessage for non-API errors', () async {
    final p = _TestProvider();
    await p.failWithMessage();
    expect(p.error, 'Friendly message');
  });

  test('unwrapList extracts items from wrapped response', () {
    final p = _TestProvider();
    final res = {'data': <Map<String, dynamic>>[{'id': '1'}]};
    expect(p.extract(res), hasLength(1));
    expect(p.extract({'data': 'not-a-list'}), isEmpty);
    expect(p.extract('garbage'), isEmpty);
  });
}
