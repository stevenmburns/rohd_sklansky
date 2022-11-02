import 'package:sklansky/sklansky.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd/src/utilities/simcompare.dart';
import 'package:test/test.dart';

void main() {
  tearDown(Simulator.reset);

  group('simcompare', () {
    test('tree', () async {

      const lg_n = 3;
      const n = 1 << lg_n;
      //const n = 12;
      final mod = Sklansky(
          List<Logic>.generate(n, (index) => Logic(width: 1)),
          (a, b) => a | b);
      await mod.build();

      final List<Vector> vectors = [];

      int compute_or_scan(i, j) {
        for (var k=0; k <= i; ++k) {
          if ((k&j) != 0) {
            return 1;
          }
        }
        return 0;
      }

      for (var j=0; j < (1<<n); ++j) {
        vectors.add(Vector({
          for (var i in List<int>.generate(n, (index) => index)) 'i$i': ((i&j)!=0)?1:0
        },
        {
          for (var i in List<int>.generate(n, (index) => index)) 'o$i': compute_or_scan(i, j)
        }));
      }

      await SimCompare.checkFunctionalVector(mod, vectors);
      final simResult = SimCompare.iverilogVector(
          mod.generateSynth(), '${mod.runtimeType}_${lg_n-1}', vectors,
          signalToWidthMap: {
            ...{
              for (var i in List<int>.generate(n, (index) => index)) 'i$i': 1
            },
            ...{
              for (var i in List<int>.generate(n, (index) => index)) 'o$i': 1
            }

          });
      expect(simResult, equals(true));
    });
  });
}
