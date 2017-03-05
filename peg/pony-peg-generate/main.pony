use "assert"
use "collections"
use "files"
use "logger"
use "options"
use "peg"


actor Main
  let _env: Env
  // Some values we can set via command line options
  var _input: String = ""
  var _loglevel: LogLevel = Warn
  var written: Set[String] = Set[String]

  new create(env: Env) =>
    _env = env
    try
      parse_args()
    else
      return
    end
    generate()

  be generate() =>
    let src = try String.from_array(read_source())
      else
        ""
      end
    // try 
      // let src = String.from_array(read_source())
      // _env.out.print(src)
    // else
      // return
    // end
    let parser = PegParser(_env, src)
    try
      let result = parser.grammar()
      let intro' = result.array()(0)
      let rules' = result.array()(1)
      let outro' = result.array()(2)
      _env.out.print(intro'.string())
      match rules'.atom()
      | let n: None => Fact(false, "No Rules!")
      else
        None
      end

      let writer = object
        let done: SetIs[Expression val] = SetIs[Expression val]
        fun ref write(e: Expression val, env: Env, main: Main ref) =>
          if not main.written.contains(e.pony_func_name()) then
            env.out.print(e.pony_method())
            main.written.set(e.pony_func_name())
            for expr in e.requires().values() do
              write(expr, env, main)
            end
          end
      end

      for r in rules'.array().values() do
        writer.write(r.array()(0).atom() as Expression val, _env, this)
      end
    else
      try Fact(false, parser.p_current_error) end
    end

  fun read_source(): Array[U8] val ?=>
    let p = FilePath(_env.root as AmbientAuth, _input)
    let f = File(p)
    f.read(65535)

  fun ref parse_args() ? =>
    var options = Options(_env.args)

    options
      .add("input", "i", StringArgument)
      .add("loglevel", "l", StringArgument)

    for option in options do
      match option
      | ("input", let arg: String) => _input = arg
      | ("loglevel", let arg: String) => match arg
        | "fine" => _loglevel = Fine
        | "info" => _loglevel = Info
        | "warn" => _loglevel = Warn
        | "error" => _loglevel = Error
        else
          _env.out.write("Unknown loglevel\n"); usage(); error
        end
      | let err: ParseError => err.report(_env.out) ; usage() ; error
      end
    end

  fun ref usage() =>
    _env.out.print("""
pony-peg-generate [OPTIONS]

OPTIONS:
  --input=FILE, -i FILE:
             The peg gramar file
  --loglevel=LEVEL, -l LEVEL:
             Log level. one of fine, info, warn, error. Default: warn
      """)
