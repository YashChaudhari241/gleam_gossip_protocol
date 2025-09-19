import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import gossip_actor.{type GossipMessage, GossipState, Rumor, SetNeighbors}

// Reduce num_nodes to perfect square/cube in case of 2d/3d
fn get_num_nodes(num_nodes: Int, topology: String) {
  let num_nodes = case topology {
    "full" | "line" -> {
      num_nodes
    }
    "2d" -> {
      num_nodes
      |> int.to_float
      |> float.square_root
      |> result.map(float.floor)
      |> result.try(float.power(_, 2.0))
      |> result.map(float.truncate)
      |> result.unwrap(0)
    }
    "3d" | "3d_imperfect" -> {
      num_nodes
      |> int.to_float
      |> float.power(1.0 /. 3.0)
      |> result.map(float.floor)
      |> result.try(float.power(_, 3.0))
      |> result.map(float.truncate)
      |> result.unwrap(0)
    }
    _ -> {
      panic as "invalid topology"
    }
  }
  num_nodes
}

pub fn initiate_gossip(
  subject_dict: Dict(Int, Subject(GossipMessage)),
  rumor: String,
) {
  let random_actor = subject_dict |> dict.values |> list.sample(1) |> list.first
  case random_actor {
    Ok(actor) -> process.send(actor, Rumor(rumor: rumor))
    Error(_) -> panic as "No actors found to initiate"
  }
}

// Start actors and initialize them
pub fn start_actors(num_nodes: Int, topology: String) {
  let num_nodes = get_num_nodes(num_nodes, topology)
  echo num_nodes
  let subject_dict =
    list.range(0, num_nodes - 1)
    |> list.map(fn(i: Int) {
      let assert Ok(actor_result) =
        actor.new(GossipState(frequency: 0, neighbors: [], index: i))
        |> actor.on_message(gossip_actor.handle_message_gossip)
        |> actor.start
      #(i, actor_result.data)
    })
    |> dict.from_list
    |> initialize_actors(num_nodes, topology)
  subject_dict
}

// set neighbors for each of the actors
fn initialize_actors(
  subject_dict: Dict(Int, Subject(GossipMessage)),
  num_nodes: Int,
  topology: String,
) -> Dict(Int, Subject(GossipMessage)) {
  dict.each(subject_dict, fn(index: Int, subject: Subject(GossipMessage)) {
    process.send(
      subject,
      SetNeighbors(get_neighbors(index, subject_dict, num_nodes, topology)),
    )
  })
  subject_dict
}

// get neighbors based on the topology
fn get_neighbors(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
  num_nodes: Int,
  topology: String,
) -> List(Subject(GossipMessage)) {
  case topology {
    "full" -> get_neighbors_full(index, subject_dict)
    "line" -> get_neighbors_line(index, subject_dict)
    "2d" -> get_neighbors_2d(index, subject_dict, num_nodes)
    "3d" -> get_neighbors_3d(index, subject_dict, num_nodes)
    "3d_imperfect" -> get_neighbors_3d_imperfect(index, subject_dict, num_nodes)
    _ -> []
  }
}

// Returns all actors except the current actor
fn get_neighbors_full(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
) -> List(Subject(GossipMessage)) {
  subject_dict |> dict.drop([index]) |> dict.values
}

// Returns adjacent actors based on ids
fn get_neighbors_line(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
) -> List(Subject(GossipMessage)) {
  [dict.get(subject_dict, index - 1), dict.get(subject_dict, index + 1)]
  |> result.values
}

// Return actors in a 2d topology
fn get_neighbors_2d(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
  num_nodes: Int,
) -> List(Subject(GossipMessage)) {
  let side =
    num_nodes
    |> int.to_float
    |> float.square_root
    |> result.map(float.truncate)
    |> result.unwrap(0)

  case index {
    // First column, only add neighbors on the right
    x if x % side == 0 -> [dict.get(subject_dict, x + 1)]
    // Last column, only add neighbors on the left
    x if { x + 1 } % side == 0 -> [dict.get(subject_dict, x - 1)]
    // Middle columns, add both actors on the sides
    x -> [
      dict.get(subject_dict, x - 1),
      dict.get(subject_dict, x + 1),
    ]
  }
  // Append The top and bottom neighbors, dont check for position as we will filter out errors in the next step
  // For the top and bottom rows, one of the vertical neighbors will be absent in the dict and return an error which we will filter out
  |> list.append([
    dict.get(subject_dict, index - side),
    dict.get(subject_dict, index + side),
  ])
  |> result.values
}

// Return actors in a 3d topology
fn get_neighbors_3d(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
  num_nodes: Int,
) -> List(Subject(GossipMessage)) {
  let side =
    num_nodes
    |> int.to_float
    |> float.power(1.0 /. 3.0)
    |> result.map(float.floor)
    |> result.map(float.truncate)
    |> result.unwrap(0)

  case index {
    //  First column, only add neighbors on the right
    x if x % side == 0 -> [dict.get(subject_dict, x + 1)]
    //  Last column, only add neighbors on the left
    x if { x + 1 } % side == 0 -> [dict.get(subject_dict, x - 1)]
    // Middle columns, add both actors on the sides
    x -> [
      dict.get(subject_dict, x - 1),
      dict.get(subject_dict, x + 1),
    ]
  }
  |> list.append(case index {
    // First row, only add neighbors on the bottom
    x if x % { side * side } < side -> [dict.get(subject_dict, index + side)]
    // Last row, only add neighbors on the top
    x if { x + side } % { side * side } < side -> [
      dict.get(subject_dict, index - side),
    ]
    // Middle row, Add both vertical neighbors
    _ -> [
      dict.get(subject_dict, index + side),
      dict.get(subject_dict, index - side),
    ]
  })
  // Add z-neighbors on both sides, we will filter out the errors for the outer most layer
  |> list.append([
    dict.get(subject_dict, index - { side * side }),
    dict.get(subject_dict, index + { side * side }),
  ])
  |> result.values
}

fn get_neighbors_3d_imperfect(
  index: Int,
  subject_dict: Dict(Int, Subject(GossipMessage)),
  num_nodes: Int,
) -> List(Subject(GossipMessage)) {
  let neighbors = get_neighbors_3d(index, subject_dict, num_nodes)

  // Filter dict such that it doesnt contain adjacent actors and self, then select a random actor
  subject_dict
  |> dict.filter(fn(k, v) { k != index && !list.contains(neighbors, v) })
  |> dict.values
  |> list.sample(1)
  |> list.append(neighbors)
  |> echo
}
