use "collections"

type ParseAtom is ( String val
                  | Array[ParseResult val] val
                  | Expression val
                  | Rule val
                  | None)

primitive Labels
  fun apply(names: Array[String]): Map[String, ParseResult val] val =>
    recover val
      let labels = Map[String, ParseResult val]
      labels
    end

class ParseResult
  let _atom: ParseAtom
  let label: String
  let _labels: (None | Map[String, ParseResult val] val)

  new val create(atom': (ParseAtom | ParseResult val),
                 label': String="",
                 labels: (None | Map[String, ParseResult val] val)=None)=>
    match atom'
    | let a: ParseAtom => _atom = a
    | let r: ParseResult val => _atom = r.atom()
    else
      _atom = ""
    end
    label = label'
    _labels = labels

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

  fun apply(k: String): ParseResult val? =>
    (_labels as Map[String, ParseResult val] val )(k)
