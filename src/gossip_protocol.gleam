import actor_topology.{initiate_gossip, start_actors}
import argv
import clip
import clip/help
import gleam/erlang/process
import gleam/io
import utils.{Args, command}

pub fn main() -> Nil {
  let args =
    command()
    |> clip.help(help.simple("lukas", "Provide N, k and batch_size(optional)"))
    |> clip.run(argv.load().arguments)

  let args = case args {
    Error(e) -> panic as { "Input error: " <> e }
    Ok(result) -> result
  }
  start_actors(args.num_nodes, args.topology)
  |> initiate_gossip("Sample rumor")
  process.sleep(10_000)
  io.println("Done")
}
