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
        lit = lit.replace("\\", "\\\\")
        lit = lit.replace('"', r'\"')
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
        return ", ".join(["value: ParseResult val"] +
            ["%s': ParseResult val" % l for l in set(self.find_labels(self.expr))])

    def pony_action_fun_name(self):
        return "_on_%s" % ponyfy_funname(self.name)

    def pony_extract_labels(self):
        result = "%s(value" % self.pony_action_fun_name()
        if self.labels:
            result += ", "
            result += ", ".join(['value("%s")' % l for l in self.labels])
        result += ")"
        return result

    def pony_code(self):
        if not self.code.strip():
            return "if true then value else error end"
        elif self.code.strip().startswith("@"):
            return "if true then %s else error end" % (self.code.strip()[1:] + "'")
        else:
            return self.code.lstrip()

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    let result = {1}()
    let labels: Array[String] = {6}
    let value = ParseResult(result where labels=Labels(labels))
    {5}

  fun ref _on_{0}({3}): ParseResult val ? =>
    {4}
        """.format(
               ponyfy_funname(self.name),
               self.expr.name,
               self.alias,
               self.pony_labels(),
               self.pony_code(),
               self.pony_extract_labels(),
               "[" + ", ".join('"%s"' % l for l in self.labels) + "]" if self.labels else "Array[String]"
              )


class Expression:
    register = []


class SeqExpr(Expression):
    counter = 0
    def __init__(self, first, rest):
        SeqExpr.counter += 1
        self.name = "seq_expr_%d" % self.counter
        self.register.append(self)
        self.first = first
        self.rest = [e for e in extract(rest, Expression)][0]

    def children(self):
        return [self.first, self.rest]

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    {1}()
    {2}()
    """.format(
           self.name,
           self.first.name,
           self.rest.name,
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

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    try
      {1}()
    else
      {2}()
    end
    """.format(
           self.name,
           self.first.name,
           self.rest.name,
        )


class RuleExpr(Expression):
    existing = set()
    def __init__(self, name):
        self.rulename = ponyfy_funname(name)
        self.name = "{}_rule".format(self.rulename)
        if self.name not in self.existing:
            self.existing.add(self.name)
            self.register.append(self)

    def children(self):
        return []

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    {1}()
    """.format(
           self.name,
           self.rulename,
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

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    if true then ParseResult("{1}") else error end
    """.format(
           self.name,
           self.lit,
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

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    ParseResult({2}() where label'="{1}")
    """.format(
           self.name,
           self.label,
           self.expr.name,
        )


class OneOrMoreExpr(Expression):
    counter = 0
    def __init__(self, expr):
        OneOrMoreExpr.counter += 1
        self.name = "one_or_more_expr%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def __str__(self):
       return """
  fun ref {0}(): ParseResult val ? =>
    let result = {1}()
    try {1}() else result end
    """.format(
           self.name,
           self.expr.name,
        )


class MaybeExpr(Expression):
    counter = 0
    def __init__(self, expr):
        MaybeExpr.counter += 1
        self.name = "maybe_expr%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    if true then
      try {1}() else ParseResult(None) end
    else error end
    """.format(
           self.name,
           self.expr.name,
        )


class NotExpr(Expression):
    counter = 0
    def __init__(self, expr):
        NotExpr.counter += 1
        self.name = "not_expr%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    try {1}() else return ParseResult(None) end
    error
    """.format(
           self.name,
           self.expr.name,
        )


class ZeroOrMoreExpr(Expression):
    counter = 0
    def __init__(self, expr):
        ZeroOrMoreExpr.counter += 1
        self.name = "zero_or_more_expr%d" % self.counter
        self.register.append(self)
        self.expr = expr

    def children(self):
        return [self.expr]

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    {1}()
    """.format(
           self.name,
           self.expr.name,
        )


class CharRangeExpr(Expression):
    counter = 0
    def __init__(self, content):
        CharRangeExpr.counter += 1
        self.name = "char_range_expr%d" % self.counter
        self.register.append(self)
        self.content = content

    def children(self):
        return []

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    if true then
        ParseResult("{1}")
    else error end
    """.format(
           self.name,
           self.content,
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

    def __str__(self):
        return """
  fun ref {0}(): ParseResult val ? =>
    if true then
      ParseResult("a")
    else error end
    """.format(
           self.name,
        )
    

grammar = r'''{// This was auto-generated. Do not edit by hand!

use "collections"


class PegParser
  let _rules: Map[String, Rule] = Map[String, Rule]
  let _env: Env
  let _sr: SourceReader

  new create(env: Env, src: String) =>
    _env=env
    _sr = SourceReader(src)
    _env.out.write("Hello\n")

  fun p_flatten(value: ParseResult val): ParseResult val ? =>
    if true then ParseResult("") else error end
}

grammar <- intro:code_block __ "{" __ rules:( rule __ )+ __ "}" {
    for r in rules'.array().values() do
      _env.out.write(r.rule().string())
    end
    value
}

rule "RULE" <- name:identifier_name __  ( :alias _ )? "<-" __ expr:expression code:( __ code_block )? EOS {
    ParseResult(recover val
        Rule(name'.string(), expr'.expr(), code'.string(), alias'.string())
    end)
}

code_block "CODE_BLOCK" <- "{" :code "}" {@code}
code <- ( ( ![{}] source_char )+ / ( "\\{" code "\\}" ) )* {p_flatten(value)}

alias "ALIAS" <- string_literal {p_flatten(value)}

expression "EXPRESSION" <- choice_expr
choice_expr <- first:seq_expr rest:( __ "/" __ seq_expr )*
primary_expr <- regexp_expr / lit_expr / char_range_expr / any_char_expr / rule_expr / sub_expr
sub_expr <- "(" __ expr:expression __ ")" {@expr}

regexp_expr <- "~" lit:string_literal flags:[iLmsux]*

lit_expr <- lit:string_literal ignore:"i"?

string_literal <- '"' content:double_string_char* '"' {@content}
double_string_char <- ( !( '"' / "\\" / EOL ) char:source_char ) / ( "\\" char:double_string_escape ) {@char}
double_string_escape <- '"' / common_escape

any_char_expr <- "."

rule_expr <- name:identifier_name !( __ (string_literal __ )? "<-" )

seq_expr <- first:labeled_expr rest:( __ labeled_expr )*

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
identifier_name <- identifier_start identifier_part* {p_flatten(value)}
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
