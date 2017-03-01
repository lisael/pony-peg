primitive PonyFuncName
  fun apply(name: String): String =>
    match name
    | "_" => "underscore"
    | "__" => "double_underscore"
    else
      name.lower()
    end

primitive PonyEscape
  fun apply(txt: String): String =>
    recover val
      var st = String(txt.size())
      st.append(txt)
      st.replace("\\", "\\\\")
      st.replace("\"", "\\\"")
      st.replace("\n", "\\n")
      st.replace("\r", "\\r")
      st.replace("\t", "\\t")
      st
   end

