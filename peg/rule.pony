use "collections"

class Rule is Expression
  let _name: String
  let _expr: Expression val
  let _code: String
  let _alias: String

  new create(name: String, expr: Expression val, code: String, alias: String) =>
    _name = name
    _expr = expr
    _code = code
    _alias = alias

  fun pony_func_name(): String =>
    PonyFuncName(_name)

  fun pony_call_rule_code(): String =>
    "// TODO: call rule code"
    let labels = _get_labels()
    var i = USize(0)
    var result = ""
    for p in labels.values() do
      let idx = i = i + 1
      result = result + 
      "      let p_label_" + idx.string() + " = try _p_current_labeled(\"" + p + "\")\n" +
      "        else\n" +
      "          ParseResult(None)\n" +
      "        end\n"
    end
    result = result + "      p_value = _on_" + pony_func_name() + "(p_value"
    for l in Range(0, labels.size()) do
      result  = result + ", p_label_" + l.string()
    end
    result + ")"


  fun pony_labels(): String =>
    var s = "value"
    for l in _get_labels().values() do
      s = s + "': ParseResult val, " + l
    end
    s = s + "': ParseResult val"
    s

  fun _get_labels(): Set[String] =>
    let s = Set[String]
    _expr.labels(s)

  fun pony_code(): String =>
    if _code == "" then
      "if true then value' else error end"
    else
      try
        if _code(0) == '@' then
          _code.substring(ISize(1)) + "'"
        else
          _code
        end
      else
        ""
      end
    end

  fun requires(): Array[Expression val] val =>
    recover val
      let res = Array[Expression val]
      res.push(_expr)
      res
    end

  fun pony_grammar(): String =>
    _name + " <- " + _expr.pony_grammar()

  fun pony_method(): String =>
    _pony_method() +
    "    let p_old_labeled = _p_current_labeled = Map[String, ParseResult val]\n" +
    "    try\n"+
    "      var p_value = " + _expr.pony_func_name() + "()\n" +
    pony_call_rule_code() + "\n" +
    "      _p_current_labeled = p_old_labeled\n" +
    "      " + pony_dedent() + "\n" +
    "      p_value\n" +
    "    else\n" +
    "      " + pony_dedent() + "\n" +
    "      _p_current_labeled = p_old_labeled\n" +
    "      error\n" +
    "    end\n\n" +

    "  fun ref _on_" + pony_func_name() + """ (""" + pony_labels() + """): ParseResult val ? =>
    ifdef debug then
      Debug(_debug_indent + "_on_""" + pony_func_name() + """")
      Debug(_debug_indent + _sr.head())
    end
    """ + pony_code() + "\n"
