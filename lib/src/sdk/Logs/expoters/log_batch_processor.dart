// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import '../../proto/opentelemetry/proto/collector/logs/v1/logs_service.pb.dart'
as pb_logs_service;


import '../../../../api.dart' as api;
import '../../../../sdk.dart' as sdk;


/// Everytime you create new realm schema you must add it in local schema array here.
// Realm getAppDatabase() {
//   final dbConfig = Configuration.local([
//     Logsdb.schema,
//   ], schemaVersion: 1);
//   return Realm(dbConfig);
// }

class LogBatchProcessor  {
  static const int _DEFAULT_MAXIMUM_BATCH_SIZE = 512;
  static const int _DEFAULT_MAXIMUM_QUEUE_SIZE = 2048;
  static const int _DEFAULT_EXPORT_DELAY = 5000;

  final sdk.LogCollectorExporter _exporter;
  final Logger _log = Logger('opentelemetry.BatchSpanProcessor');
  final int _maxExportBatchSize;
  final int _maxQueueSize;

  final List<sdk.ReadableLogRecord> _logBuffer = [];

  late final Timer _timer;

  bool _isShutdown = false;



  LogBatchProcessor(this._exporter,
      {int maxExportBatchSize = _DEFAULT_MAXIMUM_BATCH_SIZE,
        int scheduledDelayMillis = _DEFAULT_EXPORT_DELAY})
      : _maxExportBatchSize = maxExportBatchSize,
        _maxQueueSize = _DEFAULT_MAXIMUM_QUEUE_SIZE {
    _timer = Timer.periodic(
        Duration(milliseconds: scheduledDelayMillis), _exportBatch);
  }

  @override
  void forceFlush() {
    if (_isShutdown) {
      return;
    }
    while (_logBuffer.isNotEmpty) {
      _exportBatch(_timer);
    }
    _exporter.forceFlush();
  }

  @override
  void onEmit(sdk.ReadableLogRecord log) {
    if (_isShutdown) {
      return;
    }
    _addToBuffer(log);
  }

  emitBatch(int batchSize){
    //fetch batchSize data from DB and emit
    //on scuuess of emit
    // delete from DB
    // delete should be in FIFO  order
  }

  flushDB(){
    // delete  all from DB
  }

  emitOnDBMaxSizeLimit(){
    // when db size get full
    // start emiting from db untill db become half

  }

  int getDBSize(){
    // realm get db size
    return 0;
  }

  @override
  void shutdown() {
    forceFlush();
    _isShutdown = true;
    _timer.cancel();
    _exporter.shutdown();
  }

  void _addToBuffer(sdk.ReadableLogRecord log) {
    // add to db in fifo order

  }

  void _exportBatch(Timer timer) {
    if (_logBuffer.isEmpty) {
      return;
    }

    final batchSize = min(_logBuffer.length, _maxExportBatchSize);
    final batch = _logBuffer.sublist(0, batchSize);
    _logBuffer.removeRange(0, batchSize);

    _exporter.export(batch);
  }
}
