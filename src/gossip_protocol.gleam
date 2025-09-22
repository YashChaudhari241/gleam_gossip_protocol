import actor_topology.{
  initiate_gossip, start_actors, start_simulation, start_supervisor,
}
import argv
import clip
import clip/help
import gleam/erlang/process
import gleam/io
import types.{Gossip, Pushsum}
import utils.{command}

pub fn main() -> Nil {
  let args =
    command()
    |> clip.help(help.simple("lukas", "Provide N, k and batch_size(optional)"))
    |> clip.run(argv.load().arguments)

  let args = case args {
    Error(e) -> panic as { "Input error: " <> e }
    Ok(result) -> result
  }
  // let num_nodes = get_num_nodes(args.num_nodes, args.topology)
  let num_nodes = args.num_nodes
  case args.algorithm {
    "gossip" -> {
      start_supervisor(num_nodes, Gossip)
      |> start_actors(num_nodes, args.topology, Gossip)
      |> initiate_gossip("Sample rumor")
      |> start_simulation
    }
    "push-sum" -> {
      start_supervisor(num_nodes, Pushsum)
      |> start_actors(num_nodes, args.topology, Pushsum)
      |> start_simulation
    }
    _ -> {
      panic as "Invalid algorithm"
    }
  }
  process.sleep(10_000)
  io.println("Done")
}
