// This was auto-generated. Do not edit by hand!

use "collections"


class PegParser
  var _current_labeled: Map[String, ParseResult val] = Map[String, ParseResult val]
  let _env: Env
  let _sr: SourceReader

  new create(env: Env, src: String) =>
    _env=env
    _sr = SourceReader(src)

  fun p_flatten(value: ParseResult val): ParseResult val ? =>
    if true then ParseResult("") else error end


  fun ref code_block_rule(): ParseResult val ? =>
    code_block()
    

  fun ref labeled_expr1(): ParseResult val ? =>
    let p_result = code_block_rule()
    _current_labeled.insert("intro", p_result)
    

  fun ref double_underscore_rule(): ParseResult val ? =>
    double_underscore()
    

  fun ref literal_expr_1(): ParseResult val ? =>
    if true then ParseResult("{") else error end
    

  fun ref rule_rule(): ParseResult val ? =>
    rule()
    

  fun ref seq_expr_1(): ParseResult val ? =>
    rule_rule()
    double_underscore_rule()
    

  fun ref one_or_more_expr1(): ParseResult val ? =>
    let result = seq_expr_1()
    try seq_expr_1() else result end
    

  fun ref labeled_expr2(): ParseResult val ? =>
    let p_result = one_or_more_expr1()
    _current_labeled.insert("rules", p_result)
    

  fun ref literal_expr_2(): ParseResult val ? =>
    if true then ParseResult("}") else error end
    

  fun ref seq_expr_2(): ParseResult val ? =>
    double_underscore_rule()
    literal_expr_2()
    

  fun ref seq_expr_3(): ParseResult val ? =>
    labeled_expr2()
    seq_expr_2()
    

  fun ref seq_expr_4(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_3()
    

  fun ref seq_expr_5(): ParseResult val ? =>
    literal_expr_1()
    seq_expr_4()
    

  fun ref seq_expr_6(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_5()
    

  fun ref seq_expr_7(): ParseResult val ? =>
    labeled_expr1()
    seq_expr_6()
    

  fun ref identifier_name_rule(): ParseResult val ? =>
    identifier_name()
    

  fun ref labeled_expr3(): ParseResult val ? =>
    let p_result = identifier_name_rule()
    _current_labeled.insert("name", p_result)
    

  fun ref alias_rule(): ParseResult val ? =>
    alias()
    

  fun ref labeled_expr4(): ParseResult val ? =>
    let p_result = alias_rule()
    _current_labeled.insert("alias", p_result)
    

  fun ref underscore_rule(): ParseResult val ? =>
    underscore()
    

  fun ref seq_expr_8(): ParseResult val ? =>
    labeled_expr4()
    underscore_rule()
    

  fun ref maybe_expr1(): ParseResult val ? =>
    if true then
      try seq_expr_8() else ParseResult(None) end
    else error end
    

  fun ref literal_expr_3(): ParseResult val ? =>
    if true then ParseResult("<-") else error end
    

  fun ref expression_rule(): ParseResult val ? =>
    expression()
    

  fun ref labeled_expr5(): ParseResult val ? =>
    let p_result = expression_rule()
    _current_labeled.insert("expr", p_result)
    

  fun ref seq_expr_9(): ParseResult val ? =>
    double_underscore_rule()
    code_block_rule()
    

  fun ref maybe_expr2(): ParseResult val ? =>
    if true then
      try seq_expr_9() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr6(): ParseResult val ? =>
    let p_result = maybe_expr2()
    _current_labeled.insert("code", p_result)
    

  fun ref eos_rule(): ParseResult val ? =>
    eos()
    

  fun ref seq_expr_10(): ParseResult val ? =>
    labeled_expr6()
    eos_rule()
    

  fun ref seq_expr_11(): ParseResult val ? =>
    labeled_expr5()
    seq_expr_10()
    

  fun ref seq_expr_12(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_11()
    

  fun ref seq_expr_13(): ParseResult val ? =>
    literal_expr_3()
    seq_expr_12()
    

  fun ref seq_expr_14(): ParseResult val ? =>
    maybe_expr1()
    seq_expr_13()
    

  fun ref seq_expr_15(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_14()
    

  fun ref seq_expr_16(): ParseResult val ? =>
    labeled_expr3()
    seq_expr_15()
    

  fun ref literal_expr_4(): ParseResult val ? =>
    if true then ParseResult("{") else error end
    

  fun ref code_rule(): ParseResult val ? =>
    code()
    

  fun ref labeled_expr7(): ParseResult val ? =>
    let p_result = code_rule()
    _current_labeled.insert("code", p_result)
    

  fun ref literal_expr_5(): ParseResult val ? =>
    if true then ParseResult("}") else error end
    

  fun ref seq_expr_17(): ParseResult val ? =>
    labeled_expr7()
    literal_expr_5()
    

  fun ref seq_expr_18(): ParseResult val ? =>
    literal_expr_4()
    seq_expr_17()
    

  fun ref char_range_expr1(): ParseResult val ? =>
    if true then
        ParseResult("{}")
    else error end
    

  fun ref not_expr1(): ParseResult val ? =>
    try char_range_expr1() else return ParseResult(None) end
    error
    

  fun ref source_char_rule(): ParseResult val ? =>
    source_char()
    

  fun ref seq_expr_19(): ParseResult val ? =>
    not_expr1()
    source_char_rule()
    

  fun ref one_or_more_expr2(): ParseResult val ? =>
    let result = seq_expr_19()
    try seq_expr_19() else result end
    

  fun ref literal_expr_6(): ParseResult val ? =>
    if true then ParseResult("\\{") else error end
    

  fun ref literal_expr_7(): ParseResult val ? =>
    if true then ParseResult("\\}") else error end
    

  fun ref seq_expr_20(): ParseResult val ? =>
    code_rule()
    literal_expr_7()
    

  fun ref seq_expr_21(): ParseResult val ? =>
    literal_expr_6()
    seq_expr_20()
    

  fun ref choice_expr_1(): ParseResult val ? =>
    try
      one_or_more_expr2()
    else
      seq_expr_21()
    end
    

  fun ref zero_or_more_expr1(): ParseResult val ? =>
    choice_expr_1()
    

  fun ref string_literal_rule(): ParseResult val ? =>
    string_literal()
    

  fun ref choice_expr_rule(): ParseResult val ? =>
    choice_expr()
    

  fun ref seq_expr_rule(): ParseResult val ? =>
    seq_expr()
    

  fun ref labeled_expr8(): ParseResult val ? =>
    let p_result = seq_expr_rule()
    _current_labeled.insert("first", p_result)
    

  fun ref literal_expr_8(): ParseResult val ? =>
    if true then ParseResult("/") else error end
    

  fun ref seq_expr_22(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_rule()
    

  fun ref seq_expr_23(): ParseResult val ? =>
    literal_expr_8()
    seq_expr_22()
    

  fun ref seq_expr_24(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_23()
    

  fun ref zero_or_more_expr2(): ParseResult val ? =>
    seq_expr_24()
    

  fun ref labeled_expr9(): ParseResult val ? =>
    let p_result = zero_or_more_expr2()
    _current_labeled.insert("rest", p_result)
    

  fun ref seq_expr_25(): ParseResult val ? =>
    labeled_expr8()
    labeled_expr9()
    

  fun ref regexp_expr_rule(): ParseResult val ? =>
    regexp_expr()
    

  fun ref lit_expr_rule(): ParseResult val ? =>
    lit_expr()
    

  fun ref char_range_expr_rule(): ParseResult val ? =>
    char_range_expr()
    

  fun ref any_char_expr_rule(): ParseResult val ? =>
    any_char_expr()
    

  fun ref rule_expr_rule(): ParseResult val ? =>
    rule_expr()
    

  fun ref sub_expr_rule(): ParseResult val ? =>
    sub_expr()
    

  fun ref choice_expr_2(): ParseResult val ? =>
    try
      rule_expr_rule()
    else
      sub_expr_rule()
    end
    

  fun ref choice_expr_3(): ParseResult val ? =>
    try
      any_char_expr_rule()
    else
      choice_expr_2()
    end
    

  fun ref choice_expr_4(): ParseResult val ? =>
    try
      char_range_expr_rule()
    else
      choice_expr_3()
    end
    

  fun ref choice_expr_5(): ParseResult val ? =>
    try
      lit_expr_rule()
    else
      choice_expr_4()
    end
    

  fun ref choice_expr_6(): ParseResult val ? =>
    try
      regexp_expr_rule()
    else
      choice_expr_5()
    end
    

  fun ref literal_expr_9(): ParseResult val ? =>
    if true then ParseResult("(") else error end
    

  fun ref labeled_expr10(): ParseResult val ? =>
    let p_result = expression_rule()
    _current_labeled.insert("expr", p_result)
    

  fun ref literal_expr_10(): ParseResult val ? =>
    if true then ParseResult(")") else error end
    

  fun ref seq_expr_26(): ParseResult val ? =>
    double_underscore_rule()
    literal_expr_10()
    

  fun ref seq_expr_27(): ParseResult val ? =>
    labeled_expr10()
    seq_expr_26()
    

  fun ref seq_expr_28(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_27()
    

  fun ref seq_expr_29(): ParseResult val ? =>
    literal_expr_9()
    seq_expr_28()
    

  fun ref literal_expr_11(): ParseResult val ? =>
    if true then ParseResult("~") else error end
    

  fun ref labeled_expr11(): ParseResult val ? =>
    let p_result = string_literal_rule()
    _current_labeled.insert("lit", p_result)
    

  fun ref char_range_expr2(): ParseResult val ? =>
    if true then
        ParseResult("iLmsux")
    else error end
    

  fun ref zero_or_more_expr3(): ParseResult val ? =>
    char_range_expr2()
    

  fun ref labeled_expr12(): ParseResult val ? =>
    let p_result = zero_or_more_expr3()
    _current_labeled.insert("flags", p_result)
    

  fun ref seq_expr_30(): ParseResult val ? =>
    labeled_expr11()
    labeled_expr12()
    

  fun ref seq_expr_31(): ParseResult val ? =>
    literal_expr_11()
    seq_expr_30()
    

  fun ref labeled_expr13(): ParseResult val ? =>
    let p_result = string_literal_rule()
    _current_labeled.insert("lit", p_result)
    

  fun ref literal_expr_12(): ParseResult val ? =>
    if true then ParseResult("i") else error end
    

  fun ref maybe_expr3(): ParseResult val ? =>
    if true then
      try literal_expr_12() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr14(): ParseResult val ? =>
    let p_result = maybe_expr3()
    _current_labeled.insert("ignore", p_result)
    

  fun ref seq_expr_32(): ParseResult val ? =>
    labeled_expr13()
    labeled_expr14()
    

  fun ref literal_expr_13(): ParseResult val ? =>
    if true then ParseResult("\"") else error end
    

  fun ref double_string_char_rule(): ParseResult val ? =>
    double_string_char()
    

  fun ref zero_or_more_expr4(): ParseResult val ? =>
    double_string_char_rule()
    

  fun ref labeled_expr15(): ParseResult val ? =>
    let p_result = zero_or_more_expr4()
    _current_labeled.insert("content", p_result)
    

  fun ref literal_expr_14(): ParseResult val ? =>
    if true then ParseResult("\"") else error end
    

  fun ref seq_expr_33(): ParseResult val ? =>
    labeled_expr15()
    literal_expr_14()
    

  fun ref seq_expr_34(): ParseResult val ? =>
    literal_expr_13()
    seq_expr_33()
    

  fun ref literal_expr_15(): ParseResult val ? =>
    if true then ParseResult("\"") else error end
    

  fun ref literal_expr_16(): ParseResult val ? =>
    if true then ParseResult("\\") else error end
    

  fun ref eol_rule(): ParseResult val ? =>
    eol()
    

  fun ref choice_expr_7(): ParseResult val ? =>
    try
      literal_expr_16()
    else
      eol_rule()
    end
    

  fun ref choice_expr_8(): ParseResult val ? =>
    try
      literal_expr_15()
    else
      choice_expr_7()
    end
    

  fun ref not_expr2(): ParseResult val ? =>
    try choice_expr_8() else return ParseResult(None) end
    error
    

  fun ref labeled_expr16(): ParseResult val ? =>
    let p_result = source_char_rule()
    _current_labeled.insert("char", p_result)
    

  fun ref seq_expr_35(): ParseResult val ? =>
    not_expr2()
    labeled_expr16()
    

  fun ref literal_expr_17(): ParseResult val ? =>
    if true then ParseResult("\\") else error end
    

  fun ref double_string_escape_rule(): ParseResult val ? =>
    double_string_escape()
    

  fun ref labeled_expr17(): ParseResult val ? =>
    let p_result = double_string_escape_rule()
    _current_labeled.insert("char", p_result)
    

  fun ref seq_expr_36(): ParseResult val ? =>
    literal_expr_17()
    labeled_expr17()
    

  fun ref choice_expr_9(): ParseResult val ? =>
    try
      seq_expr_35()
    else
      seq_expr_36()
    end
    

  fun ref literal_expr_18(): ParseResult val ? =>
    if true then ParseResult("\"") else error end
    

  fun ref common_escape_rule(): ParseResult val ? =>
    common_escape()
    

  fun ref choice_expr_10(): ParseResult val ? =>
    try
      literal_expr_18()
    else
      common_escape_rule()
    end
    

  fun ref literal_expr_19(): ParseResult val ? =>
    if true then ParseResult(".") else error end
    

  fun ref labeled_expr18(): ParseResult val ? =>
    let p_result = identifier_name_rule()
    _current_labeled.insert("name", p_result)
    

  fun ref seq_expr_37(): ParseResult val ? =>
    string_literal_rule()
    double_underscore_rule()
    

  fun ref maybe_expr4(): ParseResult val ? =>
    if true then
      try seq_expr_37() else ParseResult(None) end
    else error end
    

  fun ref literal_expr_20(): ParseResult val ? =>
    if true then ParseResult("<-") else error end
    

  fun ref seq_expr_38(): ParseResult val ? =>
    maybe_expr4()
    literal_expr_20()
    

  fun ref seq_expr_39(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_38()
    

  fun ref not_expr3(): ParseResult val ? =>
    try seq_expr_39() else return ParseResult(None) end
    error
    

  fun ref seq_expr_40(): ParseResult val ? =>
    labeled_expr18()
    not_expr3()
    

  fun ref labeled_expr_rule(): ParseResult val ? =>
    labeled_expr()
    

  fun ref labeled_expr19(): ParseResult val ? =>
    let p_result = labeled_expr_rule()
    _current_labeled.insert("first", p_result)
    

  fun ref seq_expr_41(): ParseResult val ? =>
    double_underscore_rule()
    labeled_expr_rule()
    

  fun ref zero_or_more_expr5(): ParseResult val ? =>
    seq_expr_41()
    

  fun ref labeled_expr20(): ParseResult val ? =>
    let p_result = zero_or_more_expr5()
    _current_labeled.insert("rest", p_result)
    

  fun ref seq_expr_42(): ParseResult val ? =>
    labeled_expr19()
    labeled_expr20()
    

  fun ref identifier_rule(): ParseResult val ? =>
    identifier()
    

  fun ref maybe_expr5(): ParseResult val ? =>
    if true then
      try identifier_rule() else ParseResult(None) end
    else error end
    

  fun ref literal_expr_21(): ParseResult val ? =>
    if true then ParseResult(":") else error end
    

  fun ref seq_expr_43(): ParseResult val ? =>
    literal_expr_21()
    double_underscore_rule()
    

  fun ref seq_expr_44(): ParseResult val ? =>
    double_underscore_rule()
    seq_expr_43()
    

  fun ref seq_expr_45(): ParseResult val ? =>
    maybe_expr5()
    seq_expr_44()
    

  fun ref maybe_expr6(): ParseResult val ? =>
    if true then
      try seq_expr_45() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr21(): ParseResult val ? =>
    let p_result = maybe_expr6()
    _current_labeled.insert("label", p_result)
    

  fun ref prefixed_expr_rule(): ParseResult val ? =>
    prefixed_expr()
    

  fun ref labeled_expr22(): ParseResult val ? =>
    let p_result = prefixed_expr_rule()
    _current_labeled.insert("expr", p_result)
    

  fun ref seq_expr_46(): ParseResult val ? =>
    labeled_expr21()
    labeled_expr22()
    

  fun ref prefix_rule(): ParseResult val ? =>
    prefix()
    

  fun ref seq_expr_47(): ParseResult val ? =>
    prefix_rule()
    double_underscore_rule()
    

  fun ref maybe_expr7(): ParseResult val ? =>
    if true then
      try seq_expr_47() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr23(): ParseResult val ? =>
    let p_result = maybe_expr7()
    _current_labeled.insert("prefix", p_result)
    

  fun ref suffixed_expr_rule(): ParseResult val ? =>
    suffixed_expr()
    

  fun ref labeled_expr24(): ParseResult val ? =>
    let p_result = suffixed_expr_rule()
    _current_labeled.insert("expr", p_result)
    

  fun ref seq_expr_48(): ParseResult val ? =>
    labeled_expr23()
    labeled_expr24()
    

  fun ref primary_expr_rule(): ParseResult val ? =>
    primary_expr()
    

  fun ref labeled_expr25(): ParseResult val ? =>
    let p_result = primary_expr_rule()
    _current_labeled.insert("expr", p_result)
    

  fun ref suffix_rule(): ParseResult val ? =>
    suffix()
    

  fun ref seq_expr_49(): ParseResult val ? =>
    double_underscore_rule()
    suffix_rule()
    

  fun ref maybe_expr8(): ParseResult val ? =>
    if true then
      try seq_expr_49() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr26(): ParseResult val ? =>
    let p_result = maybe_expr8()
    _current_labeled.insert("suffix", p_result)
    

  fun ref seq_expr_50(): ParseResult val ? =>
    labeled_expr25()
    labeled_expr26()
    

  fun ref char_range_expr3(): ParseResult val ? =>
    if true then
        ParseResult("?+*")
    else error end
    

  fun ref char_range_expr4(): ParseResult val ? =>
    if true then
        ParseResult("!&")
    else error end
    

  fun ref literal_expr_22(): ParseResult val ? =>
    if true then ParseResult("[") else error end
    

  fun ref class_char_range_rule(): ParseResult val ? =>
    class_char_range()
    

  fun ref class_char_rule(): ParseResult val ? =>
    class_char()
    

  fun ref choice_expr_11(): ParseResult val ? =>
    try
      class_char_range_rule()
    else
      class_char_rule()
    end
    

  fun ref zero_or_more_expr6(): ParseResult val ? =>
    choice_expr_11()
    

  fun ref labeled_expr27(): ParseResult val ? =>
    let p_result = zero_or_more_expr6()
    _current_labeled.insert("content", p_result)
    

  fun ref literal_expr_23(): ParseResult val ? =>
    if true then ParseResult("]") else error end
    

  fun ref literal_expr_24(): ParseResult val ? =>
    if true then ParseResult("i") else error end
    

  fun ref maybe_expr9(): ParseResult val ? =>
    if true then
      try literal_expr_24() else ParseResult(None) end
    else error end
    

  fun ref labeled_expr28(): ParseResult val ? =>
    let p_result = maybe_expr9()
    _current_labeled.insert("ignore", p_result)
    

  fun ref seq_expr_51(): ParseResult val ? =>
    literal_expr_23()
    labeled_expr28()
    

  fun ref seq_expr_52(): ParseResult val ? =>
    labeled_expr27()
    seq_expr_51()
    

  fun ref seq_expr_53(): ParseResult val ? =>
    literal_expr_22()
    seq_expr_52()
    

  fun ref labeled_expr29(): ParseResult val ? =>
    let p_result = class_char_rule()
    _current_labeled.insert("start", p_result)
    

  fun ref literal_expr_25(): ParseResult val ? =>
    if true then ParseResult("-") else error end
    

  fun ref labeled_expr30(): ParseResult val ? =>
    let p_result = class_char_rule()
    _current_labeled.insert("end", p_result)
    

  fun ref seq_expr_54(): ParseResult val ? =>
    literal_expr_25()
    labeled_expr30()
    

  fun ref seq_expr_55(): ParseResult val ? =>
    labeled_expr29()
    seq_expr_54()
    

  fun ref literal_expr_26(): ParseResult val ? =>
    if true then ParseResult("]") else error end
    

  fun ref literal_expr_27(): ParseResult val ? =>
    if true then ParseResult("\\") else error end
    

  fun ref choice_expr_12(): ParseResult val ? =>
    try
      literal_expr_27()
    else
      eol_rule()
    end
    

  fun ref choice_expr_13(): ParseResult val ? =>
    try
      literal_expr_26()
    else
      choice_expr_12()
    end
    

  fun ref not_expr4(): ParseResult val ? =>
    try choice_expr_13() else return ParseResult(None) end
    error
    

  fun ref labeled_expr31(): ParseResult val ? =>
    let p_result = source_char_rule()
    _current_labeled.insert("char", p_result)
    

  fun ref seq_expr_56(): ParseResult val ? =>
    not_expr4()
    labeled_expr31()
    

  fun ref literal_expr_28(): ParseResult val ? =>
    if true then ParseResult("\\") else error end
    

  fun ref char_class_escape_rule(): ParseResult val ? =>
    char_class_escape()
    

  fun ref labeled_expr32(): ParseResult val ? =>
    let p_result = char_class_escape_rule()
    _current_labeled.insert("char", p_result)
    

  fun ref seq_expr_57(): ParseResult val ? =>
    literal_expr_28()
    labeled_expr32()
    

  fun ref choice_expr_14(): ParseResult val ? =>
    try
      seq_expr_56()
    else
      seq_expr_57()
    end
    

  fun ref literal_expr_29(): ParseResult val ? =>
    if true then ParseResult("]") else error end
    

  fun ref choice_expr_15(): ParseResult val ? =>
    try
      literal_expr_29()
    else
      common_escape_rule()
    end
    

  fun ref single_char_escape_rule(): ParseResult val ? =>
    single_char_escape()
    

  fun ref literal_expr_30(): ParseResult val ? =>
    if true then ParseResult("a") else error end
    

  fun ref literal_expr_31(): ParseResult val ? =>
    if true then ParseResult("b") else error end
    

  fun ref literal_expr_32(): ParseResult val ? =>
    if true then ParseResult("n") else error end
    

  fun ref literal_expr_33(): ParseResult val ? =>
    if true then ParseResult("f") else error end
    

  fun ref literal_expr_34(): ParseResult val ? =>
    if true then ParseResult("r") else error end
    

  fun ref literal_expr_35(): ParseResult val ? =>
    if true then ParseResult("t") else error end
    

  fun ref literal_expr_36(): ParseResult val ? =>
    if true then ParseResult("v") else error end
    

  fun ref literal_expr_37(): ParseResult val ? =>
    if true then ParseResult("\\") else error end
    

  fun ref choice_expr_16(): ParseResult val ? =>
    try
      literal_expr_36()
    else
      literal_expr_37()
    end
    

  fun ref choice_expr_17(): ParseResult val ? =>
    try
      literal_expr_35()
    else
      choice_expr_16()
    end
    

  fun ref choice_expr_18(): ParseResult val ? =>
    try
      literal_expr_34()
    else
      choice_expr_17()
    end
    

  fun ref choice_expr_19(): ParseResult val ? =>
    try
      literal_expr_33()
    else
      choice_expr_18()
    end
    

  fun ref choice_expr_20(): ParseResult val ? =>
    try
      literal_expr_32()
    else
      choice_expr_19()
    end
    

  fun ref choice_expr_21(): ParseResult val ? =>
    try
      literal_expr_31()
    else
      choice_expr_20()
    end
    

  fun ref choice_expr_22(): ParseResult val ? =>
    try
      literal_expr_30()
    else
      choice_expr_21()
    end
    

  fun ref literal_expr_38(): ParseResult val ? =>
    if true then ParseResult("#") else error end
    

  fun ref not_expr5(): ParseResult val ? =>
    try eol_rule() else return ParseResult(None) end
    error
    

  fun ref seq_expr_58(): ParseResult val ? =>
    not_expr5()
    source_char_rule()
    

  fun ref zero_or_more_expr7(): ParseResult val ? =>
    seq_expr_58()
    

  fun ref seq_expr_59(): ParseResult val ? =>
    literal_expr_38()
    zero_or_more_expr7()
    

  fun ref any_char(): ParseResult val ? =>
    if true then
      ParseResult("a")
    else error end
    

  fun ref identifier_start_rule(): ParseResult val ? =>
    identifier_start()
    

  fun ref identifier_part_rule(): ParseResult val ? =>
    identifier_part()
    

  fun ref zero_or_more_expr8(): ParseResult val ? =>
    identifier_part_rule()
    

  fun ref seq_expr_60(): ParseResult val ? =>
    identifier_start_rule()
    zero_or_more_expr8()
    

  fun ref char_range_expr5(): ParseResult val ? =>
    if true then
        ParseResult("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_")
    else error end
    

  fun ref char_range_expr6(): ParseResult val ? =>
    if true then
        ParseResult("0123456789")
    else error end
    

  fun ref choice_expr_23(): ParseResult val ? =>
    try
      identifier_start_rule()
    else
      char_range_expr6()
    end
    

  fun ref whitespace_rule(): ParseResult val ? =>
    whitespace()
    

  fun ref comment_rule(): ParseResult val ? =>
    comment()
    

  fun ref choice_expr_24(): ParseResult val ? =>
    try
      eol_rule()
    else
      comment_rule()
    end
    

  fun ref choice_expr_25(): ParseResult val ? =>
    try
      whitespace_rule()
    else
      choice_expr_24()
    end
    

  fun ref zero_or_more_expr9(): ParseResult val ? =>
    choice_expr_25()
    

  fun ref zero_or_more_expr10(): ParseResult val ? =>
    whitespace_rule()
    

  fun ref char_range_expr7(): ParseResult val ? =>
    if true then
        ParseResult(" 	")
    else error end
    

  fun ref literal_expr_39(): ParseResult val ? =>
    if true then ParseResult("
") else error end
    

  fun ref maybe_expr10(): ParseResult val ? =>
    if true then
      try comment_rule() else ParseResult(None) end
    else error end
    

  fun ref seq_expr_61(): ParseResult val ? =>
    maybe_expr10()
    eol_rule()
    

  fun ref seq_expr_62(): ParseResult val ? =>
    underscore_rule()
    seq_expr_61()
    

  fun ref eof_rule(): ParseResult val ? =>
    eof()
    

  fun ref seq_expr_63(): ParseResult val ? =>
    double_underscore_rule()
    eof_rule()
    

  fun ref choice_expr_26(): ParseResult val ? =>
    try
      seq_expr_62()
    else
      seq_expr_63()
    end
    

  fun ref not_expr6(): ParseResult val ? =>
    try any_char() else return ParseResult(None) end
    error
    

  fun ref grammar(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_7()
    p_value = _on_grammar(p_value, _current_labeled("rules"), _current_labeled("intro"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_grammar(value: ParseResult val, rules': ParseResult val, intro': ParseResult val): ParseResult val ? =>
    for r in rules'.array().values() do
      _env.out.write(r.rule().string())
    end
    value

        

  fun ref rule(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_16()
    p_value = _on_rule(p_value, _current_labeled("alias"), _current_labeled("code"), _current_labeled("name"), _current_labeled("expr"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_rule(value: ParseResult val, alias': ParseResult val, code': ParseResult val, name': ParseResult val, expr': ParseResult val): ParseResult val ? =>
    ParseResult(recover val
        Rule(name'.string(), expr'.expr(), code'.string(), alias'.string())
    end)

        

  fun ref code_block(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_18()
    p_value = _on_code_block(p_value, _current_labeled("code"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_code_block(value: ParseResult val, code': ParseResult val): ParseResult val ? =>
    if true then code' else error end
        

  fun ref code(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = zero_or_more_expr1()
    p_value = _on_code(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_code(value: ParseResult val): ParseResult val ? =>
    p_flatten(value)
        

  fun ref alias(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = string_literal_rule()
    p_value = _on_alias(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_alias(value: ParseResult val): ParseResult val ? =>
    p_flatten(value)
        

  fun ref expression(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_rule()
    p_value = _on_expression(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_expression(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref choice_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_25()
    p_value = _on_choice_expr(p_value, _current_labeled("rest"), _current_labeled("first"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_choice_expr(value: ParseResult val, rest': ParseResult val, first': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref primary_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_6()
    p_value = _on_primary_expr(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_primary_expr(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref sub_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_29()
    p_value = _on_sub_expr(p_value, _current_labeled("expr"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_sub_expr(value: ParseResult val, expr': ParseResult val): ParseResult val ? =>
    if true then expr' else error end
        

  fun ref regexp_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_31()
    p_value = _on_regexp_expr(p_value, _current_labeled("lit"), _current_labeled("flags"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_regexp_expr(value: ParseResult val, lit': ParseResult val, flags': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref lit_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_32()
    p_value = _on_lit_expr(p_value, _current_labeled("lit"), _current_labeled("ignore"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_lit_expr(value: ParseResult val, lit': ParseResult val, ignore': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref string_literal(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_34()
    p_value = _on_string_literal(p_value, _current_labeled("content"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_string_literal(value: ParseResult val, content': ParseResult val): ParseResult val ? =>
    if true then content' else error end
        

  fun ref double_string_char(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_9()
    p_value = _on_double_string_char(p_value, _current_labeled("char"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_double_string_char(value: ParseResult val, char': ParseResult val): ParseResult val ? =>
    if true then char' else error end
        

  fun ref double_string_escape(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_10()
    p_value = _on_double_string_escape(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_double_string_escape(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref any_char_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = literal_expr_19()
    p_value = _on_any_char_expr(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_any_char_expr(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref rule_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_40()
    p_value = _on_rule_expr(p_value, _current_labeled("name"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_rule_expr(value: ParseResult val, name': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref seq_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_42()
    p_value = _on_seq_expr(p_value, _current_labeled("rest"), _current_labeled("first"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_seq_expr(value: ParseResult val, rest': ParseResult val, first': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref labeled_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_46()
    p_value = _on_labeled_expr(p_value, _current_labeled("expr"), _current_labeled("label"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_labeled_expr(value: ParseResult val, expr': ParseResult val, label': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref prefixed_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_48()
    p_value = _on_prefixed_expr(p_value, _current_labeled("expr"), _current_labeled("prefix"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_prefixed_expr(value: ParseResult val, expr': ParseResult val, prefix': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref suffixed_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_50()
    p_value = _on_suffixed_expr(p_value, _current_labeled("expr"), _current_labeled("suffix"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_suffixed_expr(value: ParseResult val, expr': ParseResult val, suffix': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref suffix(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = char_range_expr3()
    p_value = _on_suffix(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_suffix(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref prefix(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = char_range_expr4()
    p_value = _on_prefix(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_prefix(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref char_range_expr(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_53()
    p_value = _on_char_range_expr(p_value, _current_labeled("content"), _current_labeled("ignore"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_char_range_expr(value: ParseResult val, content': ParseResult val, ignore': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref class_char_range(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_55()
    p_value = _on_class_char_range(p_value, _current_labeled("start"), _current_labeled("end"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_class_char_range(value: ParseResult val, start': ParseResult val, end': ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref class_char(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_14()
    p_value = _on_class_char(p_value, _current_labeled("char"))
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_class_char(value: ParseResult val, char': ParseResult val): ParseResult val ? =>
    if true then char' else error end
        

  fun ref char_class_escape(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_15()
    p_value = _on_char_class_escape(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_char_class_escape(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref common_escape(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = single_char_escape_rule()
    p_value = _on_common_escape(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_common_escape(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref single_char_escape(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_22()
    p_value = _on_single_char_escape(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_single_char_escape(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref comment(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_59()
    p_value = _on_comment(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_comment(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref source_char(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = any_char()
    p_value = _on_source_char(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_source_char(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref identifier(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = identifier_name_rule()
    p_value = _on_identifier(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_identifier(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref identifier_name(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = seq_expr_60()
    p_value = _on_identifier_name(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_identifier_name(value: ParseResult val): ParseResult val ? =>
    p_flatten(value)
        

  fun ref identifier_start(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = char_range_expr5()
    p_value = _on_identifier_start(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_identifier_start(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref identifier_part(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_23()
    p_value = _on_identifier_part(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_identifier_part(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref double_underscore(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = zero_or_more_expr9()
    p_value = _on_double_underscore(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_double_underscore(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref underscore(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = zero_or_more_expr10()
    p_value = _on_underscore(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_underscore(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref whitespace(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = char_range_expr7()
    p_value = _on_whitespace(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_whitespace(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref eol(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = literal_expr_39()
    p_value = _on_eol(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_eol(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref eos(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = choice_expr_26()
    p_value = _on_eos(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_eos(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

  fun ref eof(): ParseResult val ? =>
    let p_old_labeled = _current_labeled = Map[String, ParseResult val]
    var p_value = not_expr6()
    p_value = _on_eof(p_value)
    _current_labeled = p_old_labeled
    p_value
    

  fun ref _on_eof(value: ParseResult val): ParseResult val ? =>
    if true then value else error end
        

