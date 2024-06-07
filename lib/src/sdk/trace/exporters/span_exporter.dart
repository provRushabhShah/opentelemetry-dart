// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import '../../../../sdk.dart' as sdk;
import 'dart:typed_data';


abstract class SpanExporter {
  void export(List<sdk.ReadOnlySpan> spans);

  void forceFlush();

  void shutdown();

  exportjsonString(String jsonString,Function() onSuccess, Function() onFail  );
}
