import args.{Args, command}
import argv
import clip
import clip/help
import gleam/io

pub fn main() -> Nil {
  let args =
    command()
    |> clip.help(help.simple("lukas", "Provide N, k and batch_size(optional)"))
    |> clip.run(argv.load().arguments)

  let args = case args {
    Error(e) -> panic as { "Input error: " <> e }
    Ok(result) -> result
  }

  io.println("Done")
}
