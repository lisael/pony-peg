use "collections"
use "debug"

interface Expression
  fun string(): String => ""
  fun ref dbg(): String => "Expression `" + pony_grammar() + "`"

  fun ref pony_method(): String
    
  fun ref _pony_method(): String =>
    "  fun ref " + pony_func_name() + "(): ParseResult ? =>\n" +
    "    // " + pony_grammar() + "\n" +
    "    " + pony_debug_start()
    
  fun pony_func_name(): String => "null_expr"
  
  fun pony_dedent(): String=>
      """ifdef debug then _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1) end"""

  fun ref pony_debug_start(): String => """ifdef debug then
      _debug_indent = _debug_indent + " "
      Debug(_debug_indent + """ + "\"" + pony_func_name() + " `" + PonyEscape(pony_grammar()) + "`\")\n" +
      "      Debug(_debug_indent + _sr.head())\n" +
      "    end\n"

  fun ref pony_grammar(): String =>
    "TODO: Grammar"

  fun ref requires(): Array[Expression] =>
    Array[Expression]

  fun labels(set: Set[String]): Set[String] => set


class NullExpr is Expression
  fun ref pony_method(): String =>
    _pony_method() +
    "    if true then ParseResult(None) else error end\n"

class LabeledExpr is Expression
  let _label: String
  let _expr: Expression 
  let _rank: ISize

  new create(label: String, expr: Expression, rank: ISize) =>
    _rank = rank
    _label = label
    _expr = expr
    
  fun ref requires(): Array[Expression]=>
    [_expr]

  fun ref pony_grammar(): String =>
    _label + ":" + _expr.pony_grammar()

  fun pony_func_name(): String =>
    "labeled_expr_" + _rank.string()
    
  fun labels(set: Set[String]): Set[String] =>
    set.set(_label)
    consume set

  fun ref pony_method(): String =>
    _pony_method() + "\n" +
    "    try\n" +
    "      let p_result = " + _expr.pony_func_name() + "()\n" +
    "      _p_current_labeled.insert(\"" + _label + "\", p_result)\n" +
    "      " + pony_dedent() + "\n" +
    "      Debug(\"__insert \" + \"" + _label + " \" + p_result.dbg())\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"


class RuleExpr is Expression
  let _rule_name: String
  let _rank: ISize

  new create(rule_name': String, rank: ISize) =>
    _rank = rank
    _rule_name = rule_name'

  fun ref pony_grammar(): String =>
    _rule_name

  fun pony_func_name(): String =>
    "rule_expr_" + _rank.string()

  fun rule_name(): String =>
    _rule_name

  fun ref pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let p_result = " + PonyFuncName(_rule_name) + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n" 


class SeqExpr is Expression
  let _children: Array[Expression]
  let _rank: ISize

  new ref create(first: Expression, rest: Expression, rank: ISize) =>
    _rank = rank
    _children = Array[Expression]
    _children.push(first)
    Debug("coucou")
    match rest
    | let s: SeqExpr =>
        Debug("match")
        for res in s.children().values() do
          _children.push(res)
        end
    else
      _children.push(rest)
    end

  fun ref children(): Array[Expression] =>
    _children

  fun ref requires(): Array[Expression]=>
    _children

  fun ref pony_grammar(): String =>
    let grammars = Array[String]
    for c in _children.values() do
      grammars.push(c.pony_grammar())
    end
    " ".join(grammars)

  fun pony_func_name(): String =>
    "seq_expr_" + _rank.string()

  fun labels(set: Set[String]): Set[String] =>
    var myset = set
    for c in _children.values() do
      myset = c.labels(myset)
    end
    myset

  fun ref pony_method(): String =>
    var result = _pony_method() +
    "    try\n" + 
    "      let p_results = Array[ParseResult]\n"
    for e in _children.values() do
      result = result + "      p_results.push(" + e.pony_func_name() +"())\n"
    end
    result = result + "      let p_result = ParseResult(p_results)\n" +
    "      " + pony_dedent() + "\n" + 
    "      p_result\n" + 
    "    else\n" + 
    "      " + pony_dedent() + "\n" + 
    "      error\n" + 
    "    end\n"
    result
    
    
class ChoiceExpr is Expression
  let _first: Expression
  let _rest: Expression
  let _rank: ISize

  new create(first: Expression, rest: Expression, rank: ISize) =>
    _rank = rank
    _first = first
    _rest = rest

  fun pony_func_name(): String =>
    "choice_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    match _first
    | let e: (ChoiceExpr|SeqExpr) =>
      "( " + _first.pony_grammar() + " )"
    else
      _first.pony_grammar()
    end + " / " + match _rest
    | let e: SeqExpr =>
      "( " + _rest.pony_grammar() + " )"
    else
      _rest.pony_grammar()
    end

  fun ref requires(): Array[Expression] =>
    let res = Array[Expression]
    res.push(_first)
    res.push(_rest)
    res

  fun labels(set: Set[String]): Set[String] =>
    var myset = _first.labels(consume set)
    myset = _rest.labels(myset)
    consume myset

  fun ref pony_method(): String =>
    _pony_method() +
    "    let p_sp = _sr.save()\n" +
    "    try\n" +
    "      let p_result = " + _first.pony_func_name() + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n"+
    "    else\n" +
    "      _sr.restore(p_sp)\n" +
    "      try\n" +
    "        let p_result_2 = " + _rest.pony_func_name() + "()\n" +
    "        " + pony_dedent() + "\n" +
    "        p_result_2\n" +
    "      else\n" +
    "        " + pony_dedent() + "\n" +
    "        _sr.restore(p_sp)\n" +
    "        error\n" +
    "      end\n" +
    "    end\n"

class LiteralExpr is Expression
  let _text: String
  let _ignorecase: Bool
  let _rank: ISize

  new create(text: String, ignorecase: Bool, rank: ISize) =>
    _rank = rank
    _text = text
    _ignorecase = ignorecase

  fun pony_func_name(): String =>
    "literal_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    "\"" + PonyEscape(_text) + "\""

  fun ref pony_method(): String =>
    _pony_method() +
    "    if _sr.startswith(\"" + PonyEscape(_text) + "\", true) then\n" +
    "      " + pony_dedent() + "\n" +
    "      ParseResult(\"" + PonyEscape(_text) + "\")\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"

class ZeroOrMoreExpr is Expression
  let _expr: Expression
  let _rank: ISize

  new create(expr: Expression, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "zero_or_more_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    match _expr
    | let e: (ChoiceExpr|SeqExpr) =>
      "( " + _expr.pony_grammar() + " )*"
    else
      _expr.pony_grammar() + "*"
    end

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun ref requires(): Array[Expression]=>
    [_expr]

  fun ref pony_method(): String =>
    _pony_method() +
    "    if true then\n" +
    "      let p_results = Array[ParseResult]\n" +
    "      while true do\n" +
    "        try p_results.push(" + _expr.pony_func_name() + "()) else break end\n" +
    "      end\n" +
    "      let p_result = ParseResult(p_results)\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      error\n" +
    "    end\n"


class OneOrMoreExpr is Expression
  let _expr: Expression
  let _rank: ISize

  new create(expr: Expression, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "one_or_more_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    match _expr
    | let e: (ChoiceExpr|SeqExpr) =>
      "( " + _expr.pony_grammar() + " )+"
    else
      _expr.pony_grammar() + "+"
    end

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun ref requires(): Array[Expression]=>
    [_expr]

  fun ref pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let p_results = Array[ParseResult]\n" +
    "      p_results.push(" + _expr.pony_func_name() + "())\n" +
    "      while true do\n" +
    "        try\n" +
    "          p_results.push(" + _expr.pony_func_name() + "())\n" +
    "        else\n" +
    "          break\n" +
    "        end\n" +
    "      end\n" +
    "      let p_result = ParseResult(p_results)\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"


class MaybeExpr is Expression
  let _expr: Expression
  let _rank: ISize

  new create(expr: Expression, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "maybe_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    match _expr
    | let e: (ChoiceExpr|SeqExpr) =>
      "( " + _expr.pony_grammar() + " )?"
    else
      _expr.pony_grammar() + "?"
    end

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun ref requires(): Array[Expression]=>
    [_expr]

  fun ref pony_method(): String =>
    _pony_method() +
    "    if true then\n" +
    "      let sp=_sr.save()\n" +
    "      try\n" +
    "        let p_result = " + _expr.pony_func_name() + "()\n" +
    "        " + pony_dedent() + "\n" +
    "        p_result\n" +
    "      else\n" +
    "        _sr.restore(sp)\n" +
    "        " + pony_dedent() + "\n" +
    "        ParseResult(None)\n" +
    "      end\n" +
    "    else error end\n"

    
class NotExpr is Expression
  let _expr: Expression
  let _rank: ISize

  new create(expr: Expression, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "not_expr_" + _rank.string()

  fun ref pony_grammar(): String =>
    match _expr
    | let e: (ChoiceExpr|SeqExpr) =>
      "!( " + _expr.pony_grammar() + " )"
    else
      "!" + _expr.pony_grammar()
    end

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun ref requires(): Array[Expression]=>
    [_expr]

  fun ref pony_method(): String =>
    _pony_method() +
    "    let sp = _sr.save()\n" +
    "    try\n" +
    "      let p_result = " + _expr.pony_func_name() + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      _sr.restore(sp)\n" +
    "      return ParseResult(None)\n" +
    "    end\n" +
    "    _sr.restore(sp)\n" +
    "    error\n"

class CharRangeExpr is Expression
  // TODO: implement ignorecase
  let _text: String
  let _ignorecase: Bool
  let _rank: ISize

  new create(text: String, ignorecase: Bool, rank: ISize) =>
    _rank = rank
    _text = text
    _ignorecase = ignorecase

  fun pony_func_name(): String =>
    "char_range_expr_" + _rank.string()

  fun pony_grammar(): String =>
    "[" + PonyEscape(_text) + "]" + if _ignorecase then "i" else "" end

  fun ref pony_method(): String =>
    _pony_method() +
    "    let uchar = _sr.peak()\n" + 
    "    let char = recover val String.from_utf32(uchar) end\n" + 
    "    if \"" + PonyEscape(_text) + "\".contains(char) then\n" + 
    "      _sr.step()\n" + 
    "      " + pony_dedent() + "\n" + 
    "      ParseResult(char)\n" + 
    "    else\n" + 
    "      " + pony_dedent() + "\n" + 
    "      error\n" + 
    "    end\n"


class AnyCharExpr is Expression
  fun pony_func_name(): String =>
    "any_char_expr"

  fun pony_grammar(): String =>
    "."

  fun ref pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let char = _sr.next()\n" +
    "      " + pony_dedent() + "\n" +
    "      ParseResult(recover val String.from_utf32(char) end)\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"
