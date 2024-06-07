// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:typed_data';

import '../../../../sdk.dart' as sdk;
import 'dart:typed_data';


class ConsoleExporter implements sdk.SpanExporter {
  var _isShutdown = false;

  void _printSpans(List<sdk.ReadOnlySpan> spans) {
    for (var i = 0; i < spans.length; i++) {
      final span = spans[i];
      print({
        'traceId': '${span.spanContext.traceId}',
        'parentId': '${span.parentSpanId}',
        'name': span.name,
        'id': '${span.spanContext.spanId}',
        'timestamp': span.startTime,
        'duration': span.endTime! - span.startTime,
        'flags':
            '${span.spanContext.traceFlags.toRadixString(16).padLeft(2, '0')}',
        'state': '${span.spanContext.traceState}',
        'status': span.status.code
      });
    }
  }

  @override
  void export(List<sdk.ReadOnlySpan> spans) {
    if (_isShutdown) {
      return;
    }

    _printSpans(spans);
  }

  @override
  void forceFlush() {
    return;
  }

  @override
  void shutdown() {
    _isShutdown = true;
  }

  @override
  exportjsonString(String jsonString,Function() onSuccess, Function() onFail  ) async {
    throw UnimplementedError();
  }
  }
