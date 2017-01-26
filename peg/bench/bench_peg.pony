"""
bench_peg.pony

Bench peg stuff.
"""

use "ponybench"
use "peg"

actor Main
  let bench: PonyBench
  new create(env: Env) =>
    bench = PonyBench(env)
    bench[I32]("Add", lambda(): I32 => I32(2) + 2 end, 1000)


