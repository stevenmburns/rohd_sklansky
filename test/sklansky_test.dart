import 'package:sklansky/sklansky.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd/src/utilities/simcompare.dart';
import 'package:test/test.dart';

void main() {
  tearDown(Simulator.reset);

  group('simcompare', () {
    test('sklansky', () async {
      const n = 9;
      var inp = Logic(name: 'inp', width: n);
      final mod = OrScan(inp);
      await mod.build();

      final List<Vector> vectors = [];

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

      for (var j=0; j < (1<<n); ++j) {
        vectors.add(Vector({ 'inp': j}, {'out': computeOrScan(j)}));
      }

      await SimCompare.checkFunctionalVector(mod, vectors);
      
      final simResult = SimCompare.iverilogVector(
          mod.generateSynth(), '${mod.runtimeType}', vectors,
          signalToWidthMap: {'inp': n, 'out': n},
          dontDeleteTmpFiles: true
      );
      expect(simResult, equals(true));

    });
  });
}
