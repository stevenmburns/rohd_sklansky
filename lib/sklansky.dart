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

    int largestPow2LessThan(x) {
      var y = 1;
      while (2*y < x) {
        y *= 2;
      }
      return y;
    }

    if (_iseq.length == 1) {
      _oseq[0] <= _iseq[0];
    } else {
      final n = _iseq.length;
      final m = largestPow2LessThan(n);
      final u = Sklansky(_iseq.getRange(0, m).toList(), _op).val;
      final v = Sklansky(_iseq.getRange(m, n).toList(), _op).val;
      u.forEachIndexed((i, el) { _oseq[i] <= el; });
      v.forEachIndexed((i, el) { _oseq[m+i] <= _op(u[m-1], el); }); 
    }
  }
}

class OrScan extends Module {
  Logic get out => output('out');
  OrScan(Logic inp) {
    inp = addInput('inp', inp, width: inp.width);
    final u = Sklansky(List<Logic>.generate(inp.width, (i) => inp[i]), (a, b) => a | b);
    addOutput('out', width: inp.width) <= u.val.rswizzle();
  }
}
