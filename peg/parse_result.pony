use "collections"
use "debug"

interface Debugable
  fun dbg(): String?

type ParseAtom is ( String val
                  | Array[ParseResult val] val
                  | Debugable val
                  | None)


class ParseResult
  let _atom: ParseAtom

  new val create(atom': (ParseAtom | ParseResult val)) =>
    match atom'
    | let a: ParseAtom => _atom = a
    | let r: ParseResult val => _atom = r.atom()
    else
      _atom = ""
    end

  fun string(): String val? =>
    _atom as String val

  fun atom(): ParseAtom =>
    _atom

  fun array(): Array[ParseResult val] val? =>
    _atom as Array[ParseResult val] val

  fun none(): None? =>
    _atom as None

  fun val flatten(): ParseResult val ? =>
    match _atom
    | let s: String val => this
    | None => ParseResult("")
    | let arr: Array[ParseResult val] val =>
      var result = ""
      for r in arr.values() do
        result = result.add(r.flatten().string())
      end
      ParseResult(result)
    else
      Debug("flatten ERROR")
      error
    end

  fun dbg(): String? =>
    match _atom
    | let s: String val => "\"" + s + "\""
    | None => "None"
    | let arr: Array[ParseResult val] val =>
      var result = "["
      for r in arr.values() do
        result = result + r.dbg() + ", "
      end
      result + "]"
    | let d: Debugable val => d.dbg()
    else
      error
    end
