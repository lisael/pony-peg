"""
test_peg.pony

Test peg stuff.
"""

use "ponytest"
use "peg"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestReader)

class iso _TestReader is UnitTest

  fun name():String => "Test reader basic ops"

  fun apply(h: TestHelper) ?=>
    var sr = SourceReader("hello")

    // savepoint at origin
    var sp = sr.save()
    h.assert_is[SavePoint](sp, (0,0))

    // startswith
    h.assert_true(sr.startswith("hell"))
    h.assert_false(sr.startswith("hi"))
    
    // read a few chars
    h.assert_eq[U32](sr.next(), 'h')
    h.assert_eq[U32](sr.next(), 'e')
    h.assert_ne[U32](sr.next(), 'e')

    // restore the savepoint
    sr.restore(sp)
    // we're back at the origin
    h.assert_eq[U32](sr.next(), 'h')

    // the savepoint is now one byte/rune further
    sp = sr.save()
    h.assert_is[SavePoint](sp, (1,1))

    // consume one rune
    h.assert_true(sr.step())
    h.assert_is[SavePoint](sr.save(), (2,2))
    h.assert_eq[U32](sr.next(), 'l')
    h.assert_true(sr.step())

    // peak 
    sp = sr.save()
    h.assert_eq[U32](sr.peak(), 'o')
    h.assert_is[SavePoint](sr.save(), sp)

    // head...
    sr.restore((0,0))
    h.assert_eq[String]("hello", sr.head())
    h.assert_eq[String](sr.head(3), "hel…")


