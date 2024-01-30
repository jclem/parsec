import gleam/string
import gleeunit
import gleeunit/should
import parsec
import reader

pub fn main() {
  gleeunit.main()
}

pub fn string_empty_pass_test() {
  let parser = parsec.string("", into: parsec.into_string())

  let result =
    "Hello"
    |> reader.read_graphemes()
    |> parser()

  let assert Ok(#("", rdr)) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes("Hello"))
}

pub fn string_char_pass_test() {
  let parser = parsec.string("H", into: parsec.into_string())

  let result =
    "Hello"
    |> reader.read_graphemes()
    |> parser()

  let assert Ok(#("H", rdr)) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes("ello"))
}

pub fn string_char_fail_test() {
  let parser = parsec.string("B", into: parsec.into_string())

  let result =
    "Hello"
    |> reader.read_graphemes()
    |> parser()

  let assert Error(rdr) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes("Hello"))
}

pub fn string_chars_pass_test() {
  let parser = parsec.string("Hello", into: parsec.into_string())

  let result =
    "Hello"
    |> reader.read_graphemes()
    |> parser()

  let assert Ok(#("Hello", rdr)) = result

  reader.to_list(rdr)
  |> should.equal([])
}

pub fn string_chars_fail_test() {
  let parser = parsec.string("Hello World.", into: parsec.into_string())

  let result =
    "Hello World"
    |> reader.read_graphemes()
    |> parser()

  let assert Error(rdr) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes("Hello World"))
}

pub fn or_pass_test() {
  let parser =
    parsec.or(
      [
        parsec.string("Hello", into: parsec.into_string()),
        parsec.string("World", into: parsec.into_string()),
      ],
      into: parsec.into_string(),
    )

  let result =
    "Hello"
    |> reader.read_graphemes()
    |> parser()

  let assert Ok(#("Hello", rdr)) = result

  reader.to_list(rdr)
  |> should.equal([])
}

pub fn or_final_pass_test() {
  let parser =
    parsec.or(
      [
        parsec.string("Hello.", into: parsec.into_string()),
        parsec.string("Hello?", into: parsec.into_string()),
        parsec.string("Hello", into: parsec.into_string()),
      ],
      into: parsec.into_string(),
    )

  let result =
    "Hello World"
    |> reader.read_graphemes()
    |> parser()

  let assert Ok(#("Hello", rdr)) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes(" World"))
}

pub fn or_both_fail_test() {
  let parser =
    parsec.or(
      [
        parsec.string("Hello.", into: parsec.into_string()),
        parsec.string("Hello!", into: parsec.into_string()),
      ],
      into: parsec.into_string(),
    )

  let result =
    "Hello World"
    |> reader.read_graphemes()
    |> parser()

  let assert Error(rdr) = result

  reader.to_list(rdr)
  |> should.equal(string.to_graphemes("Hello World"))
}
