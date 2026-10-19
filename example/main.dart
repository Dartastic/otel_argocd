// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_argocd/otel_argocd.dart';

/// Traces ArgoCD calls with OpenTelemetry.
///
/// `otel_argocd` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each ArgoCD call in
/// [tracedArgocd]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'argocd-example');

  // Wraps an ArgoCD API call (apps.sync, apps.rollback, repos.list, etc.) in a CLIENT span.
  final argocdId = await tracedArgocd<String>(
    resource: 'Order',
    action: 'example',
    appName: 'example',
    project: 'example',
    revision: 'example',
    invoke: () async {
      // Make the ArgoCD call here, then report what it returned.
      return 'argocd_8f3a2c';
    },
  );
  OTelLog.info('tracedArgocd returned $argocdId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutArgocdInstrumentationAsync.
  await runWithoutArgocdInstrumentationAsync(
    () => tracedArgocd<String>(
      resource: 'Order',
      action: 'example',
      appName: 'example',
      project: 'example',
      revision: 'example',
      invoke: () async {
        return 'argocd_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
