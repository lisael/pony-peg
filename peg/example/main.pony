"""
peg.pony

Do peg stuff.
"""
use "peg"

actor Main
  new create(env: Env) =>
    env.out.print("Hello")

