import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor

pub type GossipMessage {
  Rumor(rumor: String)
  SetNeighbors(neighbors: List(Subject(GossipMessage)))
  Shutdown
}

pub type Coords {
  LinearCoords(x: Int)
  PlanarCoords(x: Int, y: Int)
  MeshCoords(x: Int, y: Int, z: Int)
}

pub type GossipState {
  GossipState(
    frequency: Int,
    neighbors: List(Subject(GossipMessage)),
    index: Int,
  )
}

pub fn handle_message_gossip(state: GossipState, msg: GossipMessage) {
  case msg {
    Rumor(rumor) -> {
      case state.frequency {
        x if x < 9 -> {
          io.println("Got gossip: " <> int.to_string(x))
          send_to_random_neighbor(state.neighbors, rumor)
        }
        _ -> {
          Nil
        }
      }
      actor.continue(GossipState(..state, frequency: state.frequency + 1))
    }
    Shutdown -> {
      actor.stop()
    }
    SetNeighbors(neighbors) -> {
      echo "Got neighbors"
      actor.continue(GossipState(..state, neighbors: neighbors))
    }
  }
}

fn send_to_random_neighbor(
  neighbors: List(Subject(GossipMessage)),
  rumor: String,
) {
  let random_neighbor_result = neighbors |> list.sample(1) |> list.first
  case random_neighbor_result {
    Ok(random_neighbor) -> {
      process.send(random_neighbor, Rumor(rumor: rumor))
    }
    Error(_) -> {
      io.println("No neighbors")
    }
  }
}
