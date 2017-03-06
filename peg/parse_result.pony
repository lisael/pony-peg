use "collections"
use "debug"

interface Debugable
  fun ref dbg(): String?

type ParseAtom is ( String
                  | Array[ParseResult]
                  | Debugable
                  | None)


class ParseResult
  let _atom: ParseAtom

  new create(atom': (ParseAtom | ParseResult)) =>
    match atom'
    | let a: ParseAtom => _atom = a
    | let r: ParseResult => _atom = r.atom()
    else
      _atom = ""
    end

  fun string(): String? =>
    _atom as String 

  fun ref atom(): ParseAtom =>
    _atom

  fun ref array(): Array[ParseResult]? =>
    _atom as Array[ParseResult] 

  fun none(): None? =>
    _atom as None

  fun ref flatten(): ParseResult ? =>
    match _atom
    | let s: String => this
    | None => ParseResult("")
    | let arr: Array[ParseResult] =>
      var result = ""
      for r in arr.values() do
        result = result.add(r.flatten().string())
      end
      ParseResult(result)
    else
      Debug("flatten ERROR")
      error
    end

  fun ref dbg(): String? =>
    match _atom
    | let s: String => "\"" + s + "\""
    | None => "None"
    | let arr: Array[ParseResult] =>
      var result = "["
      for r in arr.values() do
        result = result + r.dbg() + ", "
      end
      result + "]"
    | let d: Debugable => d.dbg()
    else
      error
    end
