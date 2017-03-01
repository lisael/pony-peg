use "collections"

interface Expression
  fun string(): String => ""
  fun dbg(): String => "Expression"

  fun pony_method(): String =>
    _pony_method() +
    "    if true then ParseResult(None) else error end\n"
    
  fun _pony_method(): String =>
    "  fun ref " + pony_func_name() + "(): ParseResult val ? =>\n" +
    "    // " + pony_grammar() + "\n" +
    "    " + pony_debug_start()
    
  fun pony_func_name(): String => "null_expr"
  
  fun pony_dedent(): String=>
      """ifdef debug then _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1) end"""

  fun pony_debug_start(): String => """ifdef debug then
      _debug_indent = _debug_indent + " "
      Debug(_debug_indent + """ + "\"" + pony_func_name() + " `" + PonyEscape(pony_grammar()) + "`\")\n" +
      "      Debug(_debug_indent + _sr.head())\n" +
      "    end\n"

  fun pony_grammar(): String =>
    "TODO: Grammar"

  fun requires(): Array[Expression val]val =>
    recover val Array[Expression val] end

  fun labels(set: Set[String]): Set[String] => set


class val NullExpr is Expression

class val LabeledExpr is Expression
  let _label: String
  let _expr: Expression val
  let _rank: ISize

  new val create(label: String, expr: Expression val, rank: ISize) =>
    _rank = rank
    _label = label
    _expr = expr
    
  fun requires(): Array[Expression val] val=>
    recover val [_expr] end

  fun pony_grammar(): String =>
    _label + ":" + _expr.pony_grammar()

  fun pony_func_name(): String =>
    "labeled_expr_" + _rank.string()
    
  fun labels(set: Set[String]): Set[String] =>
    set.set(_label)
    consume set

  fun pony_method(): String =>
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


class val RuleExpr is Expression
  let _rule_name: String
  let _rank: ISize

  new val create(rule_name': String, rank: ISize) =>
    _rank = rank
    _rule_name = rule_name'

  fun pony_grammar(): String =>
    _rule_name

  fun pony_func_name(): String =>
    "rule_expr_" + _rank.string()

  fun rule_name(): String =>
    _rule_name

  fun pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let p_result = " + PonyFuncName(_rule_name) + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n" 

class val SeqExpr is Expression
  let _children: Array[Expression val] val
  let _rank: ISize

  new val create(first: Expression val, rest: Expression val, rank: ISize) =>
    _rank = rank
    _children = recover val
      let children' = Array[Expression val]
      children'.push(first)
      match rest
      | let s: SeqExpr =>
          for res in s.children().values() do
            children'.push(res)
          end
      else
        children'.push(rest)
      end
      children'
    end

  fun children(): Array[Expression val] val=>
    _children

  fun requires(): Array[Expression val] val=>
    _children

  fun pony_grammar(): String =>
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

  fun pony_method(): String =>
    var result = _pony_method() +
    "    try\n" + 
    "      let p_result = ParseResult(recover val\n" + 
    "        let p_results = Array[ParseResult val]\n"
    for e in _children.values() do
      result = result + "        p_results.push(" + e.pony_func_name() +"())\n"
    end
    result = result + "        p_results\n" + 
    "      end)\n" + 
    "      " + pony_dedent() + "\n" + 
    "      p_result\n" + 
    "    else\n" + 
    "      " + pony_dedent() + "\n" + 
    "      error\n" + 
    "    end\n"
    result
    
    
class val ChoiceExpr is Expression
  let _first: Expression val
  let _rest: Expression val
  let _rank: ISize

  new val create(first: Expression val, rest: Expression val, rank: ISize) =>
    _rank = rank
    _first = first
    _rest = rest

  fun pony_func_name(): String =>
    "choice_expr_" + _rank.string()

  fun pony_grammar(): String =>
    _first.pony_grammar() + " / " + _rest.pony_grammar()

  fun requires(): Array[Expression val] val =>
    recover val
      let res = Array[Expression val]
      res.push(_first)
      res.push(_rest)
      res
    end

  fun labels(set: Set[String]): Set[String] =>
    var myset = _first.labels(consume set)
    myset = _rest.labels(myset)
    consume myset

  fun pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let p_result = " + _first.pony_func_name() + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n"+
    "    else\n" +
    "      try\n" +
    "        let p_result_2 = " + _rest.pony_func_name() + "()\n" +
    "        " + pony_dedent() + "\n" +
    "        p_result_2\n" +
    "      else\n" +
    "        " + pony_dedent() + "\n" +
    "        error\n" +
    "      end\n" +
    "    end\n"

class val LiteralExpr is Expression
  let _text: String
  let _ignorecase: Bool
  let _rank: ISize

  new val create(text: String, ignorecase: Bool, rank: ISize) =>
    _rank = rank
    _text = text
    _ignorecase = ignorecase

  fun pony_func_name(): String =>
    "literal_expr_" + _rank.string()

  fun pony_grammar(): String =>
    "\"" + PonyEscape(_text) + "\""

  fun pony_method(): String =>
    _pony_method() +
    "    if _sr.startswith(\"" + PonyEscape(_text) + "\", true) then\n" +
    "      " + pony_dedent() + "\n" +
    "      ParseResult(\"" + PonyEscape(_text) + "\")\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"

class val ZeroOrMoreExpr is Expression
  let _expr: Expression val
  let _rank: ISize

  new val create(expr: Expression val, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "zero_or_more_expr_" + _rank.string()

  fun pony_grammar(): String =>
    _expr.pony_grammar() + "*"

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun requires(): Array[Expression val] val=>
    recover val [_expr] end

  fun pony_method(): String =>
    _pony_method() +
    "    if true then\n" +
    "      let p_result = ParseResult(recover val\n" +
    "        let results = Array[ParseResult val]\n" +
    "        while true do\n" +
    "          try results.push(" + _expr.pony_func_name() + "()) else break end\n" +
    "        end\n" +
    "        results\n" +
    "      end)\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      error\n" +
    "    end\n"


class val OneOrMoreExpr is Expression
  let _expr: Expression val
  let _rank: ISize

  new val create(expr: Expression val, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "one_or_more_expr_" + _rank.string()

  fun pony_grammar(): String =>
    _expr.pony_grammar() + "+"

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun requires(): Array[Expression val] val=>
    recover val [_expr] end

  fun pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let p_result = ParseResult(recover val\n" +
    "      let p_results = Array[ParseResult val]\n" +
    "      p_results.push(" + _expr.pony_func_name() + "())\n" +
    "      while true do\n" +
    "        try\n" +
    "          p_results.push(" + _expr.pony_func_name() + "())\n" +
    "        else\n" +
    "          break\n" +
    "        end\n" +
    "      end\n" +
    "      p_results\n" +
    "      end)\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"


class val MaybeExpr is Expression
  let _expr: Expression val
  let _rank: ISize

  new val create(expr: Expression val, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "maybe_expr_" + _rank.string()

  fun pony_grammar(): String =>
    _expr.pony_grammar() + "?"

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun requires(): Array[Expression val] val=>
    recover val [_expr] end

  fun pony_method(): String =>
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

    
class val NotExpr is Expression
  let _expr: Expression val
  let _rank: ISize

  new val create(expr: Expression val, rank: ISize) =>
    _rank = rank
    _expr = expr

  fun pony_func_name(): String =>
    "not_expr_" + _rank.string()

  fun pony_grammar(): String =>
    "!" + _expr.pony_grammar()

  fun labels(set: Set[String]): Set[String] =>
    _expr.labels(set)

  fun requires(): Array[Expression val] val=>
    recover val [_expr] end

  fun pony_method(): String =>
    _pony_method() +
    "    let sp = _sr.save()\n" +
    "    try\n" +
    "      let p_result = " + _expr.pony_func_name() + "()\n" +
    "      " + pony_dedent() + "\n" +
    "      p_result\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      return ParseResult(None)\n" +
    "    end\n" +
    "    _sr.restore(sp)\n" +
    "    error\n"

class CharRangeExpr is Expression
  // TODO: implement char classes (0-9a-z)
  // TODO: implement ignorecase
  let _text: String
  let _ignorecase: Bool
  let _rank: ISize

  new val create(text: String, ignorecase: Bool, rank: ISize) =>
    _rank = rank
    _text = text
    _ignorecase = ignorecase

  fun pony_func_name(): String =>
    "char_range_expr_" + _rank.string()

  fun pony_grammar(): String =>
    "[" + PonyEscape(_text) + "]" + if _ignorecase then "i" else "" end

  fun pony_method(): String =>
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

  fun pony_method(): String =>
    _pony_method() +
    "    try\n" +
    "      let char = _sr.next()\n" +
    "      " + pony_dedent() + "\n" +
    "      ParseResult(recover val String.from_utf32(char) end)\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      error\n" +
    "    end\n"
