use "peg"
use "logger"
use "options"
use "files"

actor Main
  let _env: Env
  // Some values we can set via command line options
  var _input: String = ""
  var _loglevel: LogLevel = Warn

  new create(env: Env) =>
    _env = env
    try
      parse_args()
    else
      return
    end
    generate()

  be generate() =>
    try 
      let src = String.from_array(read_source())
      _env.out.print("coucou")
      _env.out.print(src)
      PegParser(_env, src)
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
