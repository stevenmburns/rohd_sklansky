import 'package:collection/collection.dart';
import 'package:rohd/rohd.dart';

int largestPow2LessThan(x) {
  var y = 1;
  while (2 * y < x) {
    y *= 2;
  }
  return y;
}

class ParallelPrefix extends Module {
  final List<Logic> _oseq = [];
  List<Logic> get val => _oseq;

  ParallelPrefix(List<Logic> inps, name): super(name: name)  {
    if (inps.isEmpty) {
      throw Exception("Don't use {name} with an empty sequence");
    }
  }
}

class Ripple extends ParallelPrefix {
  Ripple(List<Logic> inps, op) : super(inps, 'ripple') {
    final List<Logic> iseq = [];

    inps.forEachIndexed((i, el) {
      iseq.add(addInput('i$i', el, width: el.width));
      _oseq.add(addOutput('o$i', width: el.width));
    });

    for (var i=0; i<iseq.length; ++i) {
      if (i == 0) {
        _oseq[i] <= iseq[i];
      } else {
        _oseq[i] <= op(_oseq[i-1], iseq[i]);
      }

    }
  }
}

class Sklansky extends ParallelPrefix {
  Sklansky(List<Logic> inps, op) : super(inps, 'sklansky') {
    final List<Logic> iseq = [];

    inps.forEachIndexed((i, el) {
      iseq.add(addInput('i$i', el, width: el.width));
      _oseq.add(addOutput('o$i', width: el.width));
    });

    if (iseq.length == 1) {
      _oseq[0] <= iseq[0];
    } else {
      final n = iseq.length;
      final m = largestPow2LessThan(n);
      final u = Sklansky(iseq.getRange(0, m).toList(), op).val;
      final v = Sklansky(iseq.getRange(m, n).toList(), op).val;
      u.forEachIndexed((i, el) {
        _oseq[i] <= el;
      });
      v.forEachIndexed((i, el) {
        _oseq[m + i] <= op(u[m - 1], el);
      });
    }
  }
}


class OrScan extends Module {
  Logic get out => output('out');
  OrScan(Logic inp, ParallelPrefix Function(List<Logic>, Logic Function(Logic, Logic )) ppGen) {
    inp = addInput('inp', inp, width: inp.width);
    final u = ppGen(
        List<Logic>.generate(inp.width, (i) => inp[i]),
        (a, b) => a | b
    );
    addOutput('out', width: inp.width) <= u.val.rswizzle();
  }
}

class PriorityEncoder extends Module {
  Logic get out => output('out');
  PriorityEncoder(Logic inp, ParallelPrefix Function(List<Logic>, Logic Function(Logic, Logic )) ppGen) {
    inp = addInput('inp', inp, width: inp.width);
    final u = OrScan(inp, ppGen);
    addOutput('out', width: inp.width) <= (u.out & ~(u.out << Const(1)));
  }
}

class Adder extends Module {
  Logic get out => output('out');
  Adder(Logic a, Logic b, ParallelPrefix Function(List<Logic>, Logic Function(Logic, Logic )) ppGen) {
    a = addInput('a', a, width: a.width);
    b = addInput('b', b, width: b.width);
    final u = ppGen(
        List<Logic>.generate(a.width, (i) => [a[i] & b[i], a[i] | b[i]].swizzle() ),
        (lhs, rhs) => [rhs[1] | rhs[0] & lhs[1], rhs[0] & lhs[0]].swizzle()
    );
    addOutput('out', width: a.width) <= List<Logic>.generate(a.width, (i) => (i==0) ? a[i] ^ b[i] : a[i]^b[i]^u.val[i-1][1]).rswizzle();
  }
}