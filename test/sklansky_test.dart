import 'package:sklansky/sklansky.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd/src/utilities/simcompare.dart';
import 'package:test/test.dart';

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
    test('or_scan', () async {
      const n = 9;
      var inp = Logic(name: 'inp', width: n);
      final mod = OrScanRipple(inp);
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

      WaveDumper(mod);

      // put/expect testing

      for (var j=0; j < (1<<n); ++j) {
        final golden = computeOrScan(j);
        inp.put(j);
        final result = mod.out.value.toInt();
        //print("$j ${result} ${golden}");
        expect(result, equals(golden));
      }

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

    });
  });

  group('priority_encoder', () {
    test('priority_encoder', () async {
      const n = 15;
      var inp = Logic(name: 'inp', width: n);
      final mod = PriorityEncoderSklansky(inp);
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
  });
}
