// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

@TestOn('vm')
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:convert';


import 'package:mocktail/mocktail.dart';
import 'package:logging/logging.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;
import 'package:opentelemetry/src/sdk/common/limits.dart';
import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/collector/trace/v1/trace_service.pb.dart'
as pb_trace_service;

import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/collector/logs/v1/logs_service.pb.dart'
as pb_log_service;

import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/common/v1/common.pb.dart'
as pb_common;
import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/resource/v1/resource.pb.dart'
as pb_resource;
import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/trace/v1/trace.pb.dart'
as pb;

import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/logs/v1/logs.pb.dart' as pb_logs;
import 'package:opentelemetry/src/sdk/proto/opentelemetry/proto/logs/v1/logs.pbenum.dart' as pg_logs_enum;

import 'package:opentelemetry/src/sdk/trace/span.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  late MockHttpClient mockClient;
  final uri =
  Uri.parse('https://h.wdesk.org/s/opentelemetry-collector/v1/traces');
  String getHexString(List<int> _id){
    final bytes = _id;
    final buffer = StringBuffer();
    for (var byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    final hex64 = buffer.toString();
    return hex64;
  }
  setUp(() {
    mockClient = MockHttpClient();
  });

  tearDown(() {
    reset(mockClient);
  });

  test('sends logs', () {
    final resource =
    sdk.Resource([api.Attribute.fromString('service.name', 'bar')]);
    final instrumentationLibrary = sdk.InstrumentationScope(
        'library_name', 'library_version', 'url://schema', []);
    final limits = sdk.SpanLimits(maxNumAttributeLength: 5);
    final logLimit = sdk.LogLimits(maxAttributeCount: 10);
    final log1 = sdk.Logg(DateTime.now(),
                          DateTime.now(),
                          "log1",
                          api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([10, 11, 12]),
                                 api.TraceFlags.none, api.TraceState.empty()),
                          api.SpanId([4, 5, 6]),
                          [],
                          sdk.DateTimeTimeProvider(),
                          resource,
                          instrumentationLibrary,
                          logLimit)
                          ..setAttribute(api.Attribute.fromString('foo', 'bar'))
                          ..setBody(api.Attribute.fromString('body', 'bodyVal'))
                          ..setSevarity(api.Severity.debug3)
                          ..emit();
    final log2 = sdk.Logg(DateTime.now(),
                          DateTime.now(),
                          "log2",
                          api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([10, 11, 12]),
                              api.TraceFlags.none, api.TraceState.empty()),
                          api.SpanId([4, 5, 6]),
                          [],
                          sdk.DateTimeTimeProvider(),
                          resource,
                          instrumentationLibrary,
                          logLimit)
                        ..setAttribute(api.Attribute.fromString('foo', 'bar'))
                        ..setSevarity(api.Severity.debug3)
                        ..setBody(api.Attribute.fromString('body', 'bodyVal'))
                        ..emit();


    sdk.LogCollectorExporter(uri, httpClient: mockClient).export([log1,log2]);

    final expected = pb_log_service.ExportLogsServiceRequest(
      resourceLogs: [pb_logs.ResourceLogs(
          resource: pb_resource.Resource(attributes: [
            pb_common.KeyValue(
                key: 'service.name',
                value: pb_common.AnyValue(stringValue: 'bar'))
          ]),
          scopeLogs: [pb_logs.ScopeLogs(
                      logRecords: [
                        pb_logs.LogRecord(
                                        timeUnixNano : sdk.DateTimeTimeProvider().getInt64Time(log1.recordTime)  ,
                                        severityNumber: pg_logs_enum.SeverityNumber.valueOf(log1.severity!.index ),
                                        attributes: [ pb_common.KeyValue(
                                                     key: 'foo',
                                                      value: pb_common.AnyValue(stringValue: 'bar'))],
                                        traceId : getHexString([1, 2, 3]),
                                        spanId : getHexString([10, 11, 12]),
                                        body: pb_common.AnyValue(stringValue: 'body'),
                                        observedTimeUnixNano: sdk.DateTimeTimeProvider().getInt64Time(log1.observedTimestamp),
    ),pb_logs.LogRecord(
    timeUnixNano : sdk.DateTimeTimeProvider().getInt64Time(log2.recordTime) ,
    severityNumber: pg_logs_enum.SeverityNumber.valueOf(log2.severity!.index ),
    attributes: [ pb_common.KeyValue(
    key: 'foo',
    value: pb_common.AnyValue(stringValue: 'bar'))],
    traceId : getHexString([1, 2, 3]),
    spanId : getHexString([10, 11, 12]), body: pb_common.AnyValue(stringValue: 'body'),

                          observedTimeUnixNano: sdk.DateTimeTimeProvider().getInt64Time(log2.observedTimestamp),
    )],
    scope: pb_common.InstrumentationScope(
    name: 'library_name', version: 'library_version'))
    ]
      )]
    );

    print("severity index = ${ pg_logs_enum.SeverityNumber.valueOf(log1.severity!.index )}");
    final verifyResult = verify(() => mockClient.post(uri,
        body: captureAny(named: 'body'),
        headers: {'Content-Type': 'application/json'}))
      ..called(1);
    final captured = verifyResult.captured[0] as String;
    final expectedJson = expected.toProto3Json() as Map<String,dynamic>;
    final expectedJsonString = jsonEncode(expectedJson);
    expect(captured, equals(expectedJsonString));

  });
  test('does not send log when shutdown', () {

    final logLimit = sdk.LogLimits(maxAttributeCount: 10);

    final log1 = sdk.Logg(DateTime.now(),
        DateTime.now(),
        "log1",
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([10, 11, 12]),
            api.TraceFlags.none, api.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        sdk.DateTimeTimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationScope(
            'library_name', 'library_version', 'url://schema', []),
        logLimit)
    ..emit();

    sdk.LogCollectorExporter(uri, httpClient: mockClient)
      ..shutdown()
      ..export([log1]);

    verify(() => mockClient.close()).called(1);
    verifyNever(() => mockClient.post(uri,
        body: anything, headers: {'Content-Type': 'application/json'}));
  });
  test('supplies HTTP headers', () {
    final resource =
    sdk.Resource([api.Attribute.fromString('service.name', 'bar')]);
    final instrumentationLibrary = sdk.InstrumentationScope(
        'library_name', 'library_version', 'url://schema', []);
    final limits = sdk.SpanLimits(maxNumAttributeLength: 5);
    final logLimit = sdk.LogLimits(maxAttributeCount: 10);
    final log1 = sdk.Logg(DateTime.now(),
        DateTime.now(),
        "log1",
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([10, 11, 12]),
            api.TraceFlags.none, api.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        sdk.DateTimeTimeProvider(),
        resource,
        instrumentationLibrary,
        logLimit)
      ..setAttribute(api.Attribute.fromString('foo', 'bar'))
      ..setSevarity(api.Severity.debug3)
      ..emit();

    final suppliedHeaders = {
      'header-param-key-1': 'header-param-value-1',
      'header-param-key-2': 'header-param-value-2',
    };
    final expectedHeaders = {
      'Content-Type': 'application/json',
      ...suppliedHeaders,
    };

    sdk.LogCollectorExporter(uri, httpClient: mockClient, headers: suppliedHeaders)
        .export([log1]);

    verify(() => mockClient.post(uri, body: anything, headers: expectedHeaders))
        .called(1);
  });

}
