/// Copyright (C) 2021 Intel Corporation
/// SPDX-License-Identifier: BSD-3-Clause
///
/// skylansky.dart
/// An example taking advantage of some of ROHD's generation capabilities.
///
/// 2022 November 1
/// Author: Steve Burns <steven.m.burns@intel.com>
///

// ignore_for_file: avoid_print

import 'package:rohd/rohd.dart';
import 'package:sklansky/sklansky.dart';

Future<void> main({bool noPrint = false}) async {
  final Logic inp = Logic(name: 'inp', width: 9);
  final tree = PriorityEncoderSklansky(inp);
  await tree.build();
  final generatedSystemVerilog = tree.generateSynth();
  if (!noPrint) {
    print(generatedSystemVerilog);
  }
}