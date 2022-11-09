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
  const n = 256;
  final Logic a = Logic(name: 'a', width: n);
  final Logic b = Logic(name: 'b', width: n);

  final block = Adder(a, b, Sklansky.new);
  await block.build();
  final generatedSystemVerilog = block.generateSynth();
  if (!noPrint) {
    print(generatedSystemVerilog);
  }
}