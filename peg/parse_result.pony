use "collections"

type ParseAtom is ( String val
                  | Array[ParseResult val] val
                  | Expression val
                  | Rule val
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

  fun expr(): Expression val ? =>
    _atom as Expression val

  fun rule(): Rule val ? =>
    _atom as Rule val

  fun flatten(): ParseResult val =>
    try
      ParseResult(string())
    else
      var result = ""
      try
        let arr = array()
        for r in arr.values() do
          result = result.add(r.flatten().string())
        end
      end
      ParseResult(result)
    end
