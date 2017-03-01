use "collections"

type SavePoint is (USize, USize)

class SourceReader is Iterator[U32]
  let _string: String box
  var _i: USize
  var _runes: USize

  new create(string: String box, start: USize=0, runes: USize=0) =>
    _string = string
    _i = start
    _runes = runes

  fun has_next(): Bool =>
    _i < _string.size()

  fun ref next(): U32 ? =>
    (let rune, let len) = _string.utf32(_i.isize())
    _i = _i + len.usize()
    _runes = _runes + 1
    rune

  fun peak(): U32 ? =>
    (let rune, let len) = _string.utf32(_i.isize())
    rune

  fun ref step(): Bool=>
    // next() raises an error iff _i >= _string.size() in String.utf32()
    // save a comparison and a function call
    try next(); true else false end

  fun ref startswith(s: String, eat: Bool=false): Bool =>
    let result = _string.at(s, _i.isize())
    if eat and result then
      _i = _i + s.size()
      _runes = _runes + s.codepoints()
    end
    result

  fun clone_iso(): SourceReader iso^ =>
    let sr = recover iso SourceReader(_string, _i, _runes) end
    consume sr

  fun ref forward(len: USize) =>
    _i = _i + len

  fun save(): SavePoint =>
    (_i, _runes)

  fun ref restore(savepoint: SavePoint) =>
    (_i, _runes) = savepoint

  fun since(savepoint: SavePoint): String iso^ =>
    (let i: USize, _) = savepoint
    _string.substring(i.isize(), _i.isize())

  fun head(nrunes: ISize = 15): String =>
    recover val
      let result = String(USize(nrunes.usize() * 4))
      var length: ISize = 0
      var done = false
      // result.push_utf32('a')
      for i in Range[ISize](0, nrunes) do
        // result.push_utf32('a')
        (let rune, let len) = try _string.utf32(_i.isize() + length) else done = true; (0,0) end
        if done then break end
        length = length + len.isize()
        result.push_utf32(rune)
      end
      if (done != true ) then
        result.append("…")
      end
      result
    end


