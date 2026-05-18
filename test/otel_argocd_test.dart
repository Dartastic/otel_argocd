// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_argocd/otel_argocd.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_argocd-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('apps.sync records CLIENT span', () async {
    await tracedArgocd<String>(
      resource: 'apps',
      action: 'sync',
      appName: 'orders-app',
      project: 'prod',
      revision: 'HEAD',
      invoke: () async => 'synced',
    );
    final a = attrsOf(spans.findSpanByName('argocd apps.sync')!);
    expect(a['cd.system'], 'argocd');
    expect(a['argocd.app.name'], 'orders-app');
    expect(a['argocd.project'], 'prod');
    expect(a['argocd.revision'], 'HEAD');
  });

  test('suppression skips spans', () async {
    await runWithoutArgocdInstrumentationAsync(() async {
      await tracedArgocd<String>(
        resource: 'apps',
        action: 'list',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('argocd '), isEmpty);
  });
}
