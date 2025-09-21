import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import types.{
  type GossipMessage, type GossipState, Rumor, RumorGossipState, SetNeighbors,
  Shutdown, SimulateRound,
}

pub fn handle_message_gossip(state: GossipState, msg: GossipMessage) {
  case state {
    RumorGossipState(frequency, neighbors, rumor, index, supervisor, self) -> {
      case msg {
        SimulateRound(_) -> {
          case frequency {
            x if x < 10 && x > 0 ->
              send_to_random_neighbor(
                state.neighbors,
                state.rumor |> option.unwrap(""),
              )
            _ -> {
              process.send(supervisor, types.RoundComplete)
            }
          }
          actor.continue(state)
        }
        Rumor(rumor) -> {
          process.send(supervisor, types.RoundComplete)
          // io.println("got rumor")
          case state.frequency {
            0 -> process.send(state.supervisor, types.GossipNodeConverged)
            _ -> Nil
          }
          actor.continue(
            RumorGossipState(
              ..state,
              frequency: state.frequency + 1,
              rumor: Some(rumor),
            ),
          )
        }
        Shutdown -> {
          actor.stop()
        }
        SetNeighbors(neighbors, self) -> {
          actor.continue(
            RumorGossipState(..state, neighbors: neighbors, self: self),
          )
        }
        _ -> actor.continue(state)
      }
    }
    _ -> panic as "Incorrect state type"
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
