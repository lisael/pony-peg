#! /usr/bin/env python
from fastidious import Parser
from fastidious.expressions import NoMatch
import string


## utils

def ponyfy_classname(name):
    if name == "_":
        return "Underscore"
    if name == "__":
        return "DoubleUnderscore"
    split = name.replace('_', " ")
    split = split.capitalize()
    if split[0] == ' ':
        split[0] = '_'
    return ''.join(split.split())


def ponyfy_funname(name):
    if name == "_":
        return "underscore"
    if name == "__":
        return "double_underscore"
    return name.lower()


def extract(lst, klass):
    for r in lst:
        if isinstance(r, list):
            for rr in extract(r, klass):
                yield rr
        elif isinstance(r, klass):
            yield r


def ponyfy_string(s):
    for (orig, dest) in (
        ('\\', "\\\\"),
        ('"', '\\"'),
        ('\n', '\\n'),
        ('\t', '\\t'),
        ('\r', '\\r'),
    ):
        s = s.replace(orig, dest)
    return s


def flatten(obj, **kwargs):
    """ Flatten a list of lists of lists... of strings into a string

    This is usually used as the action for sequence expressions:

    .. code-block::

        my_rule <- 'a' . 'c' { p_flatten }

    With the input "abc" and no action, this rule returns [ 'a', 'b', 'c'].
    { p_flatten } procuces "abc".

    >>> parser.p_flatten(['a', ['b', 'c']])
    'abc'

    """
    if isinstance(obj, basestring):
        return obj
    result = ""
    for i in obj:
        result += flatten(i)
    return result


class PonypPEGBootstraper(Parser):
    # __debug___ = True

    __grammar__ = r"""
        grammar <- intro:code_block __ rules:( rule __ )+ outro:(code_block __)?

        rule "RULE" <- name:identifier_name __  ( :alias _ )? "<-" __ expr:expression code:( __ code_block )? EOS

        code_block "CODE_BLOCK" <- "{" :code "}" {@code}
        code <- ( ( ![{}] source_char )+ / ( "{" code "}" ) )* {p_flatten}

        alias "ALIAS" <- string_literal {p_flatten}

        expression "EXPRESSION" <- choice_expr
        # choice_expr <- first:seq_expr rest:( __ "/" __ seq_expr )*
        choice_expr <- first:seq_expr rest:( __ "/" __ choice_expr )?
        primary_expr <- regexp_expr / lit_expr / char_range_expr / any_char_expr / rule_expr / sub_expr
        sub_expr <- "(" __ expr:expression __ ")" {@expr}

        regexp_expr <- "~" lit:string_literal flags:[iLmsux]*

        lit_expr <- lit:string_literal ignore:"i"?

        string_literal <- ( '"' content:double_string_char* '"' ) / ( "'" content:single_string_char* "'" ) {@content}
        double_string_char <- ( !( '"' / "\\" / EOL ) char:source_char ) / ( "\\" char:double_string_escape ) {@char}
        single_string_char <- ( !( "'" / "\\" / EOL ) char:source_char ) / ( "\\" char:single_string_escape ) {@char}
        single_string_escape <- "'" / common_escape
        double_string_escape <- '"' / common_escape

        any_char_expr <- "."

        rule_expr <- name:identifier_name !( __ (string_literal __ )? "<-" )

        # seq_expr <- first:labeled_expr rest:( __ labeled_expr )*
        seq_expr <- first:labeled_expr rest:( __ seq_expr )?

        labeled_expr <- label:( identifier? __ ":" __ )? expr:prefixed_expr

        prefixed_expr <- prefix:( prefix __ )? expr:suffixed_expr
        suffixed_expr <- expr:primary_expr suffix:( __ suffix )?
        suffix <- [?+*]
        prefix <- [!&]

        char_range_expr <- "[" content:( class_char_range / class_char )* "]" ignore:"i"?
        class_char_range <- start:class_char "-" end:class_char
        class_char <- ( !( "]" / "\\" / EOL ) char:source_char ) / ( "\\" char:char_class_escape ) {@char}
        char_class_escape <- "]" / common_escape

        common_escape <- single_char_escape
        single_char_escape <- "a" / "b" / "n" / "f" / "r" / "t" / "v" / "\\"

        comment <- "#" ( !EOL source_char )*

        source_char <- .
        identifier <- identifier_name
        identifier_name <- identifier_start identifier_part* {p_flatten}
        identifier_start <- [A-Za-z_]
        identifier_part <- identifier_start / [0-9]

        __ <- ( whitespace / EOL / comment )*
        _ <- whitespace*
        whitespace <- [ \t\r]
        EOL <- "\n"
        EOS <- ( _ comment? EOL ) / ( __ EOF )
        EOF <- !.
    """

    def on_code_block(self, value, code=""):
        return flatten(code)

    def on_grammar(self, value, intro='', rules=None, outro=''):
        print(intro)
        rules = rules if rules else []
        for expr in Expression.register:
            print(expr)
        for rule in extract(rules, Rule):
            print(rule)
        print(outro)

    def on_terminal(self, value):
        return True

    def on_seq_expr(self, value, first=None, rest=None):
        if not rest:
            return first
        else:
            return SeqExpr(first, rest)

    def on_choice_expr(self, value, first, rest):
        if not rest:
            return first
        else:
            return ChoiceExpr(first, rest)

    def on_rule_expr(self, value, name):
        return RuleExpr(name)

    def on_lit_expr(self, value, lit, ignore=None):
        lit = flatten(lit)
        # lit = lit.replace("\\", "\\\\")
        # lit = lit.replace('"', r'\"')
        return LiteralExpr(lit, bool(ignore))

    def on_any_char_expr(self, value):
        return AnyCharExpr()

    def on_regexp_expr(self, value, lit, flags):
        return RegexExpr(lit, flags)

    def on_labeled_expr(self, value, label, expr):
        if not label:
            return expr
        if label[0] == "":
            try:
                label[0] = expr.rulename
            except AttributeError:
                raise Exception(
                    "Label can be omitted only on rule reference"
                )
        return LabeledExpr(label[0], expr)

    def on_prefixed_expr(self, value, prefix, expr):
        if not prefix:
            return expr
        prefix = prefix[0]
        if prefix == "!":
            return NotExpr(expr)
        elif prefix == "&":
            return LookAhead(expr)

    def on_suffixed_expr(self, value, suffix, expr):
        if not suffix:
            return expr
        suffix = suffix[1]
        if suffix == "?":
            return MaybeExpr(expr)
        elif suffix == "+":
            return OneOrMoreExpr(expr)
        elif suffix == "*":
            return ZeroOrMoreExpr(expr)

    def on_char_range_expr(self, value, content, ignore):
        content = self.p_flatten(content)
        if ignore == "i":
            # don't use sets to avoid ordering mess
            content = content.lower()
            upper = content.upper()
            content += "".join([c for c in upper if c not in content])
        return CharRangeExpr(content)

    def on_class_char_range(self, value, start, end):
        try:
            if start.islower():
                charset = string.lowercase
            elif start.isupper():
                charset = string.uppercase
            elif start.isdigit():
                charset = string.digits
            starti = charset.index(start)
            endi = charset.index(end)
            assert starti <= endi
            return charset[starti:endi+1]
        except:
            raise
            self.parse_error(
                "Invalid char range : `{}`".format(self.p_flatten(value)))

    _escaped = {
        "a": "\a",
        "b": "\b",
        "t": "\t",
        "n": "\n",
        "f": "\f",
        "r": "\r",
        "v": "\v",
        "\\": "\\",
    }

    def on_common_escape(self, value):
        return self._escaped[self.p_flatten(value)]

    def on_rule(self, value, name, expr, code=None, alias=None):
        alias = None if alias is NoMatch else alias
        if not isinstance(expr, Expression):
            exprs = [e for e in extract(expr, Expression)]
            # print(name)
            # print(expr)
            expr = exprs[0]
        if code:
            code = "".join([s for s in extract(code, str)])
        return Rule(name, expr, code, alias)



class Rule:
    def __init__(self, name, expr, code, alias):
        self.name = name
        self.expr = expr
        self.code = code
        self.alias = alias if alias else ""
        self._labels = None

    def find_labels(self, expr):
        result = []
        for child in expr.children():
            if isinstance(child, LabeledExpr):
                result.append(child.label)
            elif isinstance(child, RuleExpr):
                continue
            result = result + self.find_labels(child)
        return result

    @property
    def labels(self):
        if self._labels is None:
            self._labels = [l for l in set(self.find_labels(self.expr))]
        return self._labels

    def pony_labels(self):
        return ", ".join(["value': ParseResult val"] +
            ["%s': ParseResult val" % l for l in set(self.find_labels(self.expr))])

    def pony_action_fun_name(self):
        return "_on_%s" % ponyfy_funname(self.name)

    def pony_call_rule_code(self):
        result = ""
        if self.labels:
            for i, label in enumerate(self.labels):
                result += """
    let p_label_{0} = try _p_current_labeled("{1}")
    else
      ParseResult(None)
    end
      """.format(i, label)
        result += """
    p_value = %s(p_value""" % self.pony_action_fun_name()
        if self.labels:
            result += ", "
            result += ", ".join(['p_label_%d' % i for i in range(len(self.labels))])
        result += ")"
        return result

    def pony_code(self):
        if not self.code.strip():
            return "if true then value' else error end"
        elif self.code.strip().startswith("@"):
            return "if true then %s else error end" % (self.code.strip()[1:] + "'")
        else:
            return self.code.lstrip()

    def grammar(self):
        return "{} <- {}".format(self.name, self.expr.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {6}
    ifdef debug then
      _debug_indent = _debug_indent + " "
      Debug(_debug_indent + "{0} `{6}`")
      Debug(_debug_indent + _sr.head())
    end
    let p_old_labeled = _p_current_labeled = Map[String, ParseResult val]
    try
      var p_value = {1}()
      {5}
      _p_current_labeled = p_old_labeled
      ifdef debug then
        _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1)
      end
      p_value
    else
      ifdef debug then
        _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1)
      end
      _p_current_labeled = p_old_labeled
      error
    end

  fun ref _on_{0}({3}): ParseResult val ? =>
    ifdef debug then
      Debug(_debug_indent + "_on_{0}")
      Debug(_debug_indent + _sr.head())
    end
    {4}
        """.format(
               ponyfy_funname(self.name),
               self.expr.name,
               self.alias,
               self.pony_labels(),
               self.pony_code(),
               self.pony_call_rule_code(),
               ponyfy_string(self.grammar()),
              )


class Expression:
    register = []
    pony_dedent = """ifdef debug then
      _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1)
    end"""

    def pony_call(self, meth):
        return """ifdef debug then
      try
        {0}()
      else
        _debug_indent = _debug_indent.substring(0, _debug_indent.size().isize() - 1)
        error
      end
    else
      {0}()
    end""".format(meth)

    def pony_debug(self):
        return """ifdef debug then
      _debug_indent = _debug_indent + " "
      Debug(_debug_indent + "{1} `{0}`")
      Debug(_debug_indent + _sr.head())
    end""".format(ponyfy_string(self.grammar()), self.name)


class SeqExpr(Expression):
    counter = 0
    def __init__(self, first, rest):
        SeqExpr.counter += 1
        self.name = "seq_expr_%d" % self.counter
        self.register.append(self)
        self._children = [first]
        rest = [e for e in extract(rest, Expression)][0]
        if isinstance(rest, SeqExpr):
            self._children += rest.children()
        else:
            self._children.append(rest)

    def children(self):
        return self._children

    def grammar(self):
        return " ".join([c.grammar() for c in self._children])

    def pony_call_children(self):
        return "\n        ".join(["p_results.push({}())".format(c.name)
                                  for c in self._children])

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    try
      let p_result = ParseResult(recover val
        let p_results = Array[ParseResult val]
        {1}
        p_results
      end)
      {4}
      p_result
    else
      {4}
      error
    end
    """.format(
           self.name,
           self.pony_call_children(),
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class ChoiceExpr(Expression):
    counter = 0
    def __init__(self, first, rest):
        ChoiceExpr.counter += 1
        self.name = "choice_expr_%d" % self.counter
        self.register.append(self)
        self.first = first
        self.rest = [e for e in extract(rest, Expression)][0]

    def children(self):
        return [self.first, self.rest]

    def grammar(self):
        return "{} / {}".format(self.first.grammar(), self.rest.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {3}
    {4}
    let p_sp = _sr.save()
    try
      let p_result = {1}()
      {5}
      p_result
    else
      _sr.restore(p_sp)
      try
        let p_result_2 = {2}()
        {5}
        p_result_2
      else
        {5}
        _sr.restore(p_sp)
        error
      end
    end
    """.format(
           self.name,
           self.first.name,
           self.rest.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class RuleExpr(Expression):
    existing = set()
    def __init__(self, name):
        self.rawname = name
        self.rulename = ponyfy_funname(name)
        self.name = "{}_rule".format(self.rulename)
        if self.name not in self.existing:
            self.existing.add(self.name)
            self.register.append(self)

    def children(self):
        return []

    def grammar(self):
        return "{}".format(self.rawname)

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    try
      let p_result = {1}()
      {4}
      p_result
    else
      {4}
      error
    end
    """.format(
           self.name,
           self.rulename,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class LiteralExpr(Expression):
    counter = 0
    def __init__(self, lit, ignore):
        LiteralExpr.counter += 1
        self.name = "literal_expr_%d" % self.counter
        self.register.append(self)
        self.lit = lit
        self.ignore = ignore

    def children(self):
        return []

    def grammar(self):
        return '"{}"{}'.format(ponyfy_string(self.lit), "i" if self.ignore else "")

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    if _sr.startswith("{1}", true) then
      {4}
      ParseResult("{1}")
    else
      {4}
      error
    end
    """.format(
           self.name,
           ponyfy_string(self.lit),
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
           # self.ignore and "true" or "false",
        )


class LabeledExpr(Expression):
    counter = 0
    def __init__(self, label, expr):
        LabeledExpr.counter += 1
        self.name = "labeled_expr%d" % self.counter
        self.register.append(self)
        self.label = label
        self.expr = expr

    def children(self):
        return [self.expr]

    def grammar(self):
        return "{}:{}".format(self.label, self.expr.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {3}
    {4}
    try
      let p_result = {2}()
      _p_current_labeled.insert("{1}", p_result)
      {5}
      Debug("__insert " + "{1} " + p_result.dbg())
      p_result
    else
      {5}
      error
    end
    """.format(
           self.name,
           self.label,
           self.expr.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class OneOrMoreExpr(Expression):
    counter = 0
    def __init__(self, expr):
        OneOrMoreExpr.counter += 1
        self.name = "one_or_more_expr_%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def grammar(self):
        if isinstance(self.expr, (SeqExpr, ChoiceExpr)):
            return "({})+".format(self.expr.grammar())
        else:
            return "{}+".format(self.expr.grammar())


    def __str__(self):
       return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    try
      let p_result = ParseResult(recover val
      let p_results = Array[ParseResult val]
      p_results.push({1}())
      while true do
        try
          p_results.push({1}())
        else
          break
        end
      end
      p_results
      end)
      {4}
      p_result
    else
      {4}
      error
    end
    """.format(
           self.name,
           self.expr.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class MaybeExpr(Expression):
    counter = 0
    def __init__(self, expr):
        MaybeExpr.counter += 1
        self.name = "maybe_expr_%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def grammar(self):
        if isinstance(self.expr, (SeqExpr, ChoiceExpr)):
            return "({})?".format(self.expr.grammar())
        else:
            return "{}?".format(self.expr.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    // the method has to raise. It won't. Ever.
    if true then
      let sp=_sr.save()
      try
        let p_result = {1}()
        {4}
        p_result
      else
        _sr.restore(sp)
        {4}
        ParseResult(None)
      end
    else error end
    """.format(
           self.name,
           self.expr.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class NotExpr(Expression):
    counter = 0
    def __init__(self, expr):
        NotExpr.counter += 1
        self.name = "not_expr_%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def grammar(self):
        if isinstance(self.expr, (SeqExpr, ChoiceExpr)):
            return "!({})".format(self.expr.grammar())
        else:
            return "!{}".format(self.expr.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    let sp = _sr.save()
    try
      let p_result = {1}()
      {4}
      p_result
    else
      {4}
      _sr.restore(sp)
      return ParseResult(None)
    end
    _sr.restore(sp)
    error
    """.format(
           self.name,
           self.expr.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class ZeroOrMoreExpr(Expression):
    counter = 0
    def __init__(self, expr):
        ZeroOrMoreExpr.counter += 1
        self.name = "zero_or_more_expr_%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def grammar(self):
        if isinstance(self.expr, (SeqExpr, ChoiceExpr)):
            return "({})*".format(self.expr.grammar())
        else:
            return "{}*".format(self.expr.grammar())

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    if true then
      let p_result = ParseResult(recover val
        let results = Array[ParseResult val]
        while true do
          try results.push({1}()) else break end
        end
        results
      end)
      {4}
      p_result
    else
      error
    end
    """.format(
           self.name,
           self.expr.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class CharRangeExpr(Expression):
    counter = 0
    def __init__(self, content):
        CharRangeExpr.counter += 1
        self.name = "char_range_expr_%d" % self.counter
        self.register.append(self)
        self.content = content

    def children(self):
        return []

    def grammar(self):
        content = self.content.replace("abcdefghijklmnopqrstuvwxyz", "a-z")
        content = content.replace("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "A-Z")
        content = content.replace("0123456789", "0-9")
        return "[{}]".format(ponyfy_string(content))

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {2}
    {3}
    let uchar = _sr.peak()
    let char = recover val String.from_utf32(uchar) end
    if "{1}".contains(char) then
      _sr.step()
      {4}
      ParseResult(char)
    else
      {4}
      error
    end
    """.format(
           self.name,
           ponyfy_string(self.content),
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


class AnyCharExpr(Expression):
    created = False
    def __init__(self):
        self.name = "any_char"
        if not self.__class__.created:
            self.__class__.created = True
            self.register.append(self)

    def children(self):
        return []

    def grammar(self):
        return "."

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    // {1}
    {2}
    try
      let char = _sr.next()
      {3}
      ParseResult(recover val String.from_utf32(char) end)
    else
      {3}
      error
    end
    """.format(
           self.name,
           ponyfy_string(self.grammar()),
           self.pony_debug(),
           self.pony_dedent,
        )


r"""
        grammar <- intro:code_block __ rules:( rule __ )+ outro:(code_block __)?

        rule "RULE" <- name:identifier_name __  ( :alias _ )? "<-" __ expr:expression code:( __ code_block )? EOS

        code_block "CODE_BLOCK" <- "{" :code "}" {@code}
        code <- ( ( ![{}] source_char )+ / ( "{" code "}" ) )* {p_flatten}

        alias "ALIAS" <- string_literal {p_flatten}

        expression "EXPRESSION" <- choice_expr
        # choice_expr <- first:seq_expr rest:( __ "/" __ seq_expr )*
        choice_expr <- first:seq_expr rest:( __ "/" __ choice_expr )?
        primary_expr <- regexp_expr / lit_expr / char_range_expr / any_char_expr / rule_expr / sub_expr
        sub_expr <- "(" __ expr:expression __ ")" {@expr}

        regexp_expr <- "~" lit:string_literal flags:[iLmsux]*

        lit_expr <- lit:string_literal ignore:"i"?

        string_literal <- ( '"' content:double_string_char* '"' ) / ( "'" content:single_string_char* "'" ) {@content}
        double_string_char <- ( !( '"' / "\\" / EOL ) char:source_char ) / ( "\\" char:double_string_escape ) {@char}
        single_string_char <- ( !( "'" / "\\" / EOL ) char:source_char ) / ( "\\" char:single_string_escape ) {@char}
        single_string_escape <- "'" / common_escape
        double_string_escape <- '"' / common_escape

        any_char_expr <- "."

        rule_expr <- name:identifier_name !( __ (string_literal __ )? "<-" )

        # seq_expr <- first:labeled_expr rest:( __ labeled_expr )*
        seq_expr <- first:labeled_expr rest:( __ seq_expr )?

        labeled_expr <- label:( identifier? __ ":" __ )? expr:prefixed_expr

        prefixed_expr <- prefix:( prefix __ )? expr:suffixed_expr
        suffixed_expr <- expr:primary_expr suffix:( __ suffix )?
        suffix <- [?+*]
        prefix <- [!&]

        char_range_expr <- "[" content:( class_char_range / class_char )* "]" ignore:"i"?
        class_char_range <- start:class_char "-" end:class_char
        class_char <- ( !( "]" / "\\" / EOL ) char:source_char ) / ( "\\" char:char_class_escape ) {@char}
        char_class_escape <- "]" / common_escape

        common_escape <- single_char_escape
        single_char_escape <- "a" / "b" / "n" / "f" / "r" / "t" / "v" / "\\"

        comment <- "#" ( !EOL source_char )*

        source_char <- .
        identifier <- identifier_name
        identifier_name <- identifier_start identifier_part* {p_flatten}
        identifier_start <- [A-Za-z_]
        identifier_part <- identifier_start / [0-9]

        __ <- ( whitespace / EOL / comment )*
        _ <- whitespace*
        whitespace <- [ \t\r]
        EOL <- "\n"
        EOS <- ( _ comment? EOL ) / ( __ EOF )
        EOF <- !."""


grammar = r'''{// This was auto-generated. Do not edit by hand!
use "collections"
use "debug"


class PegParser
  var _p_current_labeled: Map[String, ParseResult val] = Map[String, ParseResult val]
  var p_current_error: String = ""
  let _env: Env
  let _sr: SourceReader
  var _debug_indent: String = ""
  var _rank: ISize = 0

  new create(env: Env, src: String) =>
    _env=env
    _sr = SourceReader(src)
    _debug_indent = ""

  fun ref _p_get_rank(): ISize =>
    _rank = _rank + 1
}

grammar <- intro:code_block __ rules:( rule __ )+ outro:(code_block __)? {
    if true then ParseResult(recover val [intro', rules', outro'] end) else error end
}


rule "RULE" <- name:identifier_name __  ( :alias _ )? "<-" __ expr:expression code:( __ code_block )? EOS {
    ParseResult(recover val
        Rule(name'.string(), expr'.atom() as Expression val, try code'.array()(1).string() else "" end, try alias'.string() else "" end)
    end)
}

code_block "CODE_BLOCK" <- "{" :code "}" {@code}

code <- ( ( ![{}] source_char )+ / ( "{" code "}" ) )* {Debug(value'.dbg());value'.flatten()}

alias "ALIAS" <- string_literal {value'.flatten()}

expression "EXPRESSION" <- choice_expr

choice_expr <- first:seq_expr rest:( __ "/" __ choice_expr )? {
    match rest'.atom()
    | None => first'
    else
      ParseResult(recover val
        ChoiceExpr(
          first'.atom() as Expression val,
          rest'.array()(3).atom() as Expression val,
          _p_get_rank()
        )
      end)
    end
}
primary_expr <- regexp_expr / lit_expr / char_range_expr / any_char_expr / sub_expr / rule_expr
sub_expr <- "(" __ expr:expression __ ")" {@expr}

regexp_expr <- "~" lit:string_literal flags:[iLmsux]*

lit_expr <- lit:string_literal ignore:"i"? {
    ParseResult(recover val
      LiteralExpr(
        lit'.string(),
        try ignore'.none(); false else true end,
        _p_get_rank()
      )
    end)
}

string_literal <- '"' content:double_string_char* '"' {content'.flatten()}
double_string_char <- ( !( '"' / "\\" / EOL ) char:source_char ) / ( "\\" char:double_string_escape ) {@char}
double_string_escape <- '"' / common_escape

any_char_expr <- "." {
    if true then ParseResult(AnyCharExpr) else error end
}

rule_expr <- name:identifier_name !( __ (string_literal __ )? "<-" ){
  if true then ParseResult(RuleExpr(name'.string(), _p_get_rank())) else error end
}

seq_expr <- first:labeled_expr rest:( __ seq_expr )?{
    match rest'.atom()
    | None => first'
    else
      ParseResult(recover val
        SeqExpr(
          first'.atom() as Expression val,
          rest'.array()(1).atom() as Expression val,
          _p_get_rank()
        )
      end)
    end
}

labeled_expr <- label:( identifier? __ ":" __ )? expr:prefixed_expr {
    try
      label'.none()
      return expr'
    end
    let p_id = label'.array()(0)
    let p_label = match p_id.atom()
    | None =>
      try
        let p_rule = expr'.atom() as RuleExpr
        p_rule.rule_name()
      else
        p_current_error = "Label can be omitted only on rule reference"
      end
    | let s: String => s
    else
      error
    end
    ParseResult(LabeledExpr(p_label, expr'.atom() as Expression val, _p_get_rank()))  
}

prefixed_expr <- prefix:( prefix __ )? expr:suffixed_expr{
  try
    prefix'.none()
    return expr'
  end
  match prefix'.array()(0).string()
  | "!" => ParseResult(recover val
    NotExpr(
      expr'.atom() as Expression val,
      _p_get_rank()
    ) end)
  // TODO: implement LookAhead...
  else
    error
  end
}

suffixed_expr <- expr:primary_expr suffix:( __ suffix )?{
    try
      suffix'.none()
      return expr'
    end
    let suf = suffix'.array()(1).string()
    match suf
    | "*" => ParseResult(recover val
      ZeroOrMoreExpr(
        expr'.atom() as Expression val,
        _p_get_rank()
      ) end) 
    | "?" => ParseResult(recover val
      MaybeExpr(
        expr'.atom() as Expression val,
        _p_get_rank()
      ) end) 
    | "+" => ParseResult(recover val
      OneOrMoreExpr(
        expr'.atom() as Expression val,
        _p_get_rank()
      ) end)
    else
      error
    end
}

suffix <- [?+*]
prefix <- [!&]

char_range_expr <- "[" content:( class_char_range / class_char )* "]" ignore:"i"? {
    ParseResult(
      CharRangeExpr(
        content'.flatten().string(),
        try ignore'.string() == "i" else false end,
        _p_get_rank()
      )
    )
}

class_char_range <- start:class_char "-" end:class_char{
    match (start'.string(), end'.string())
    | ("a", "z") => ParseResult("abcdefghijklmnopqrstuvwxyz")
    | ("A", "Z") => ParseResult("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    | ("0", "9") => ParseResult("0123456789")
    | ("1", "9") => ParseResult("123456789")
    else
      error
    end
}

class_char <- ( !( "]" / "\\" / EOL ) char:source_char ) / ( "\\" char:char_class_escape ) {@char}
char_class_escape <- "]" / common_escape

common_escape <- single_char_escape {
    match value'.string()
    | "a" => ParseResult("\a")
    | "b" => ParseResult("\b")
    | "n" => ParseResult("\n")
    | "f" => ParseResult("\f")
    | "r" => ParseResult("\r")
    | "t" => ParseResult("\t")
    | "v" => ParseResult("\v")
    | "\\" => ParseResult("\\\\")
    else
      error
    end
}

single_char_escape <- [abnfrtv\\]

comment <- "#" ( !EOL source_char )*

source_char <- .
identifier <- identifier_name
identifier_name <- identifier_start identifier_part* {Debug(value'.dbg());value'.flatten()}
identifier_start <- [A-Za-z_]
identifier_part <- identifier_start / [0-9]

__ <- ( whitespace / EOL / comment )*
_ <- whitespace*
whitespace <- [ \t\r]
EOL <- "\n"
EOS <- ( _ comment? EOL ) / ( __ EOF )
EOF <- !.
'''

if __name__ == "__main__":
    import sys
    # c = PonypPEGBootstraper("".join(sys.argv[1:]))
    c = PonypPEGBootstraper.p_parse(grammar)
    # import ipdb 
    # result = c.eval()
    # because eval is the first rule defined in the grammar, it's the default rule.
    # We could call the classmethod `p_parse`:
    # result = Calculator.p_parse("".join(sys.argv[1:]))
    # The default entry point can be overriden setting the class attribute
    # `__default__`
    # print(result)
