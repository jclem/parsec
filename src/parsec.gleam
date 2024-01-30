import gleam/list
import gleam/string
import gleam/string_builder.{type StringBuilder}
import reader.{type Reader}

/// A Builder provides an initial accumulator, a fold function for calculating
/// intermediate values, and a final function for calculating a final value.
///
/// Its purpose is to allow us to build up a value while parsing, and then
/// calculate the final value once parsing is complete.
pub type Builder(value, accum, result) =
  #(accum, fn(accum, value) -> accum, fn(accum) -> result)

/// A Parser is a function that takes a Reader and returns a Result.
/// 
/// The result includes the state of the reader, regardless of whether it is
/// successful or not. This allows us to subsequent parsers to continue from
/// where a previous or failed parser left off.
pub type Parser(input, result) =
  fn(Reader(input)) -> Result(#(result, Reader(input)), Reader(input))

pub fn into_string() {
  do_into_string(string_builder.new())
}

fn do_into_string(builder) -> Builder(String, StringBuilder, String) {
  #(builder, string_builder.append, string_builder.to_string)
}

pub fn or(
  one_of parsers: List(Parser(input, result)),
  into builder: Builder(result, accum, final_result),
) -> Parser(input, final_result) {
  fn(rdr) {
    case do_or(rdr, parsers, builder) {
      Ok(#(v, rdr)) -> Ok(#(v.2(v.0), rdr))
      Error(rdr) -> Error(rdr)
    }
  }
}

fn do_or(
  rdr: Reader(input),
  parsers: List(Parser(input, result)),
  into: Builder(result, accum, final_result),
) -> Result(
  #(Builder(result, accum, final_result), Reader(input)),
  Reader(input),
) {
  let result =
    list.fold_until(parsers, Error(rdr), fn(_, parser) {
      case parser(rdr) {
        Ok(#(v, rdr)) -> list.Stop(Ok(#(v, rdr)))
        Error(rdr) -> list.Continue(Error(rdr))
      }
    })

  case result {
    Ok(#(v, rd)) -> Ok(#(#(into.1(into.0, v), into.1, into.2), rd))
    Error(rd) -> Error(rd)
  }
}

pub fn string(
  read match: String,
  into builder: Builder(String, accum, result),
) -> fn(Reader(String)) -> Result(#(result, Reader(String)), Reader(String)) {
  fn(rdr) {
    case do_string(rdr, match, builder) {
      Ok(#(v, rdr)) -> Ok(#(v.2(v.0), rdr))
      Error(rdr) -> Error(rdr)
    }
  }
}

fn do_string(
  rdr: Reader(String),
  match_str,
  into: Builder(String, accum, result),
) -> Result(#(Builder(String, accum, result), Reader(String)), Reader(String)) {
  case match_str {
    "" -> Ok(#(into, rdr))
    match_str -> {
      let reader_read = reader.read(rdr)
      let string_read = string.pop_grapheme(match_str)

      case #(reader_read, string_read) {
        #(Ok(#(v, rd)), Ok(#(v2, match_str))) if v == v2 ->
          case do_string(rd, match_str, #(into.1(into.0, v), into.1, into.2)) {
            Ok(#(v, rd)) -> Ok(#(v, rd))

            // Push values back onto the front of the reader since we failed to parse.
            Error(rd) -> Error(reader.push_front(rd, v))
          }

        #(Ok(#(v, rd)), _) -> Error(reader.push_front(rd, v))

        _ -> Error(rdr)
      }
    }
  }
}
