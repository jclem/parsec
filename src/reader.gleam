import gleam/iterator
import gleam/list
import gleam/queue
import gleam/result
import gleam/string

pub opaque type Reader(a) {
  Reader(iter: iterator.Iterator(a), queue: queue.Queue(a))
}

/// Create a reader from an iterator.
pub fn read_iterator(it) {
  Reader(iter: it, queue: queue.new())
}

/// Create a grapheme reader from a string.
pub fn read_graphemes(str) -> Reader(String) {
  read_iterator({
    use str <- iterator.unfold(str)

    case string.pop_grapheme(str) {
      Ok(#(grapheme, str)) -> iterator.Next(grapheme, str)
      Error(Nil) -> iterator.Done
    }
  })
}

/// Push a value back onto the reader's front.
pub fn push_front(reader: Reader(a), value: a) -> Reader(a) {
  Reader(reader.iter, queue.push_front(reader.queue, value))
}

/// Read the next value from the reader.
pub fn read(reader: Reader(a)) {
  let result = {
    use #(val, q) <- result.try(queue.pop_front(reader.queue))
    Ok(#(val, Reader(reader.iter, q)))
  }

  case result {
    Ok(out) -> Ok(out)

    Error(Nil) ->
      case iterator.step(reader.iter) {
        iterator.Next(value, iter) -> Ok(#(value, Reader(iter, queue.new())))
        iterator.Done -> Error(Nil)
      }
  }
}

/// Read the entire reader into a list.
pub fn to_list(reader: Reader(a)) -> List(a) {
  reader
  |> do_to_list([])
  |> list.reverse()
}

fn do_to_list(reader: Reader(a), accum: List(a)) -> List(a) {
  let result = read(reader)

  case result {
    Ok(#(value, reader)) -> do_to_list(reader, [value, ..accum])
    Error(Nil) -> accum
  }
}
