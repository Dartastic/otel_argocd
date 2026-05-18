// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_argocd_suppression.dart';

const _tracerName = 'dartastic_otel_libs_argocd';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an ArgoCD API call (apps.sync, apps.rollback, repos.list,
/// etc.) in a CLIENT span.
Future<T> tracedArgocd<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? appName,
  String? project,
  String? revision,
}) async {
  if (argocdInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cd.system': 'argocd',
    'argocd.resource': resource,
    'argocd.action': action,
    'argocd.operation': '$resource.$action',
  };
  if (appName != null) m['argocd.app.name'] = appName;
  if (project != null) m['argocd.project'] = project;
  if (revision != null) m['argocd.revision'] = revision;

  final span = _tracer().startSpan(
    'argocd $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
