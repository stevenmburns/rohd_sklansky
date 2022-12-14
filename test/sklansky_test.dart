import 'package:sklansky/sklansky.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd/src/utilities/simcompare.dart';
import 'dart:math';
import 'package:test/test.dart';

void testOrScan(int n, fn) {
  test('or_scan_$n', () async {
    var inp = Logic(name: 'inp', width: n);
    final mod = fn(inp);
    await mod.build();

    int computeOrScan(j) {
      var result = 0;
      var found = false;
      for (var i = 0; i < n; ++i) {
        if (found || ((1 << i) & j) != 0) {
          result |= 1 << i;
          found = true;
        }
      }
      return result;
    }

    // put/expect testing

    for (var j = 0; j < (1 << n); ++j) {
      final golden = computeOrScan(j);
      inp.put(j);
      final result = mod.out.value.toInt();
      //print("$j ${result} ${golden}");
      expect(result, equals(golden));
    }

    /*
      WaveDumper(mod);

      // SimCompare testing
      final List<Vector> vectors = List<Vector>.generate(1<<n, (j) =>
        Vector({ 'inp': j}, {'out': computeOrScan(j)})
      );

      await SimCompare.checkFunctionalVector(mod, vectors);
      
      final simResult = SimCompare.iverilogVector(
          mod.generateSynth(), '${mod.runtimeType}', vectors,
          signalToWidthMap: {'inp': n, 'out': n},
          dontDeleteTmpFiles: true
      );
      expect(simResult, equals(true));
      */
  });
}

void testPriorityEncoder(int n, fn) {
  test('priority_encoder_$n', () async {
    var inp = Logic(name: 'inp', width: n);
    final mod = fn(inp);
    await mod.build();

    int computePriorityEncoding(j) {
      for (var i = 0; i < n; ++i) {
        if (((1 << i) & j) != 0) {
          return 1 << i;
        }
      }
      return 0;
    }

    // put/expect testing

    for (var j = 0; j < (1 << n); ++j) {
      final golden = computePriorityEncoding(j);
      inp.put(j);
      final result = mod.out.value.toInt();
      // print("priority_encoder: $j ${result} ${golden}");
      expect(result, equals(golden));
    }
  });
}

void testAdder(int n, fn) {
  test('adder_$n', () async {
    var a = Logic(name: 'a', width: n);
    var b = Logic(name: 'b', width: n);

    final mod = fn(a, b);
    await mod.build();

    int computeAdder(aa, bb) {
      return (aa + bb) & ((1 << n) - 1);
    }

    // put/expect testing

    for (var aa = 0; aa < (1 << n); ++aa) {
      for (var bb = 0; bb < (1 << n); ++bb) {
        final golden = computeAdder(aa, bb);
        a.put(aa);
        b.put(bb);
        final result = mod.out.value.toInt();
        //print("adder: $aa $bb $result $golden");
        expect(result, equals(golden));
      }
    }

    WaveDumper(mod);

    // SimCompare testing
    final List<Vector> vectors = [];
    for (var aa = 0; aa < (1 << n); ++aa) {
      for (var bb = 0; bb < (1 << n); ++bb) {
        final golden = computeAdder(aa, bb);
        vectors.add(Vector({'a': aa, 'b': bb}, {'out': golden}));
      }
    }

    await SimCompare.checkFunctionalVector(mod, vectors);
      
    final simResult = SimCompare.iverilogVector(
      mod.generateSynth(), '${mod.runtimeType}', vectors,
      signalToWidthMap: {'a': n, 'b': n, 'out': n},
      dontDeleteTmpFiles: true
    );
    expect(simResult, equals(true));
  });
}

BigInt genRandomBigInt(int nBits) {
  BigInt result = BigInt.from(0);
  while (nBits > 0) {
    var shaveOff = min(16, nBits);
    result =
        (result << shaveOff) + BigInt.from(Random().nextInt(1 << shaveOff));
    nBits -= shaveOff;
  }
  return result;
}

void testAdderRandom(int n, int nSamples, fn) {
  test('adder_$n', () async {
    var a = Logic(name: 'a', width: n);
    var b = Logic(name: 'b', width: n);

    final mod = fn(a, b);
    await mod.build();

    BigInt computeAdder(aa, bb) {
      return (aa + bb) & ((BigInt.from(1) << n) - BigInt.from(1));
    }
    // put/expect testing

    for (var i = 0; i < nSamples; ++i) {
      var aa = genRandomBigInt(n);
      var bb = genRandomBigInt(n);
      final golden = computeAdder(aa, bb);
      a.put(aa);
      b.put(bb);
      final result = mod.out.value.toBigInt();
      //print("adder: ${aa.toRadixString(16)} ${bb.toRadixString(16)} ${result.toRadixString(16)} ${golden.toRadixString(16)}");
      expect(result, equals(golden));
    }

      

      
  });
}

void testIncr(int n, fn) {
  test('incr_$n', () async {
    var inp = Logic(name: 'inp', width: n);
    final mod = fn(inp);
    await mod.build();

    int computeIncr(aa) {
      return (aa + 1) & ((1 << n) - 1);
    }

    // put/expect testing

    for (var aa = 0; aa < (1 << n); ++aa) {
      final golden = computeIncr(aa);
      inp.put(aa);
      final result = mod.out.value.toInt();
      //print("incr: $aa $result $golden");
      expect(result, equals(golden));
    }
  });
}

void testDecr(int n, fn) {
  test('decr_$n', () async {
    var inp = Logic(name: 'inp', width: n);
    final mod = fn(inp);
    await mod.build();

    int computeDecr(aa) {
      return (aa - 1) % (1 << n);
    }

    // put/expect testing

    for (var aa = 0; aa < (1 << n); ++aa) {
      final golden = computeDecr(aa);
      inp.put(aa);
      final result = mod.out.value.toInt();
      //print("decr: $aa $result $golden");
      expect(result, equals(golden));
    }
  });
}

void main() {
  tearDown(Simulator.reset);

  group('largest_pow2_less_than', () {
    test('largest_pow2_less_than', () async {
      expect(largestPow2LessThan(5), equals(4));
      expect(largestPow2LessThan(4), equals(2));
      expect(largestPow2LessThan(3), equals(2));
    });
  });

  final generators = [Ripple.new, Sklansky.new, KoggeStone.new, BrentKung.new];

  group('or_scan', () {
    for (var n in [7, 8, 9]) {
      for (var ppGen in generators) {
        testOrScan(n, (inp) => OrScan(inp, ppGen));
      }
    }
  });

  group('priority_encoder', () {
    for (var n in [7, 8, 9]) {
      for (var ppGen in generators) {
        testPriorityEncoder(n, (inp) => PriorityEncoder(inp, ppGen));
      }
    }
  });

  group('adder', () {
    for (var n in [3, 4, 5]) {
      for (var ppGen in generators) {
        testAdder(n, (a, b) => Adder(a, b, ppGen));
      }
    }
  });

  group('adderRandom', () {
    for (var n in [127,128,129]) {
      for (var ppGen in generators) {
        testAdderRandom(n, 10, (a, b) => Adder(a, b, ppGen));
      }
    }
  });

  group('incr', () {
    for (var n in [7, 8, 9]) {
      for (var ppGen in generators) {
        testIncr(n, (inp) => Incr(inp, ppGen));
      }
    }
  });

  group('decr', () {
    for (var n in [7, 8, 9]) {
      for (var ppGen in generators) {
        testDecr(n, (inp) => Decr(inp, ppGen));
      }
    }
  });
}
