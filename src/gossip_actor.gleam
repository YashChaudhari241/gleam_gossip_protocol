import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import types.{
  type GossipMessage, type GossipState, type SupervisorMessage, GossipState,
  Received, Rumor, SetNeighbors, Shutdown, SimulateRound,
}

pub fn handle_message_gossip(state: GossipState, msg: GossipMessage) {
  case msg {
    SimulateRound(_) -> {
      case state.frequency {
        0 -> Nil
        x if x < 10 ->
          send_to_random_neighbor(
            state.neighbors,
            state.rumor |> option.unwrap(""),
          )
        _ -> Nil
      }
      actor.continue(state)
    }
    Rumor(rumor) -> {
      // io.println("got rumor")
      case state.frequency {
        0 -> process.send(state.supervisor, Received)
        _ -> Nil
      }
      actor.continue(
        GossipState(..state, frequency: state.frequency + 1, rumor: Some(rumor)),
      )
    }
    Shutdown -> {
      actor.stop()
    }
    SetNeighbors(neighbors, self) -> {
      actor.continue(GossipState(..state, neighbors: neighbors, self: self))
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
