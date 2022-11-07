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
        for (var i=0; i<n; ++i) {
          if (found || ((1<<i) & j) != 0) {
            result |= 1<<i;
            found = true;
          }
        }
        return result;
      }

      // put/expect testing

      for (var j=0; j < (1<<n); ++j) {
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
        for (var i=0; i<n; ++i) {
          if (((1<<i) & j) != 0) {
            return 1<<i;
          }
        }
        return 0;
      }

      // put/expect testing

      for (var j=0; j < (1<<n); ++j) {
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
        return (aa + bb) & ((1<<n)-1);
      }

      // put/expect testing

      for (var aa=0; aa < (1<<n); ++aa) {
        for (var bb=0; bb < (1<<n); ++bb) {

          final golden = computeAdder(aa, bb);
          a.put(aa);
          b.put(bb);
          final result = mod.out.value.toInt();
          //print("adder: $aa $bb $result $golden");
          expect(result, equals(golden));
        }
      }
    }); 
}

BigInt genRandomBigInt(int nBits) {
  BigInt result = BigInt.from(0);
  while (nBits > 0) {
    var shaveOff = min(16, nBits);
    result = (result << shaveOff) + BigInt.from(Random().nextInt(1<<shaveOff));
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
        return (aa + bb) & ((BigInt.from(1)<<n)-BigInt.from(1));
      }
      // put/expect testing

      for (var i=0; i<nSamples; ++i) {
        var aa = genRandomBigInt(n);
        var bb = genRandomBigInt(n);
        final golden = computeAdder(aa, bb);
        a.put(aa);
        b.put(bb);
        final result = mod.out.value.toBigInt();
        print("adder: $aa $bb $result $golden");
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

  group('or_scan', () {
    for (var n in [7,8,9]) {
      for (var ppGen in [Ripple.new, Sklansky.new]) {
        testOrScan(n, (inp) => OrScan(inp, ppGen));
      }
    }
  });

  group('priority_encoder', () {
    for (var n in [7,8,9]) {
      for (var ppGen in [Ripple.new, Sklansky.new]) {
        testPriorityEncoder(n, (inp) => PriorityEncoder(inp, ppGen));
      }
    }
  });

  group('adder', () {
    for (var n in [3,4,5]) {
      for (var ppGen in [Ripple.new, Sklansky.new]) {
        testAdder(n, (a, b) => Adder(a, b, ppGen));
      }
    }
  });

    group('adderRandom', () {
    for (var n in [650]) {
      for (var ppGen in [Ripple.new, Sklansky.new]) {
        testAdderRandom(n, 10, (a, b) => Adder(a, b, ppGen));
      }
    }
  });
}
