import 'package:collection/collection.dart';
import 'package:rohd/rohd.dart';

class Sklansky extends Module {
  final Logic Function(Logic a, Logic b) _op;
  final List<Logic> _iseq = [];
  final List<Logic> _oseq = [];

  List<Logic> get val => _oseq;

  Sklansky(List<Logic> inps, this._op)
      : super(name: 'sklansky') {
    if (inps.isEmpty) {
      throw Exception("Don't use Sklansky with an empty sequence");
    }

    inps.forEachIndexed((i, el) {
      _iseq.add(addInput('i$i', el, width: el.width));
      _oseq.add(addOutput('o$i', width: el.width));
    });

    if (_iseq.length == 1) {
      _oseq[0] <= _iseq[0];
    } else {
      final m = _iseq.length ~/ 2;
      final n = _iseq.length;
      final u = Sklansky(_iseq.getRange(0, m).toList(), _op).val;
      final v = Sklansky(_iseq.getRange(m, n).toList(), _op).val;
      u.forEachIndexed((i, el) { _oseq[i] <= el; });
      v.forEachIndexed((i, el) { _oseq[m+i] <= _op(u[m-1], el); }); 
    }
  }
}

class OrScan extends Module {

  Logic get val => output('out');

  OrScan(Logic inp) {
    final List<Logic> _iseq = [];
    inp = addInput( 'inp', inp, width: inp.width);
    final out = addOutput( 'out', width: inp.width);
    for (var i=0; i<inp.width; ++i) {
      _iseq.add(inp[i]);
    }
    final u = Sklansky(_iseq, (a, b) => a | b);
    out <= u.val.rswizzle();
  }
}
