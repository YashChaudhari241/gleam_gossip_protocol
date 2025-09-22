import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/otp/actor
import types.{
  type GossipMessage, type GossipState, GetRatio, PushsumGossipState,
  PushsumMessage, PushsumNodeConverged, SetNeighbors, Shutdown, SimulateRound,
}

pub fn handle_msg_pushsum(state: GossipState, msg: GossipMessage) {
  case state {
    PushsumGossipState(
      neighbors,
      s,
      w,
      _index,
      supervisor,
      _self,
      termination_count,
    ) -> {
      case msg {
        GetRatio(caller) -> {
          process.send(caller, s /. w)
          actor.continue(state)
        }
        SetNeighbors(neighbors, self) -> {
          actor.continue(
            PushsumGossipState(..state, neighbors: neighbors, self: self),
          )
        }
        SimulateRound(_) -> {
          case termination_count {
            x if x < 3 -> {
              let new_s = s /. 2.0
              let new_w = w /. 2.0
              send_to_random_neighbor(neighbors, new_s, new_w)
              actor.continue(PushsumGossipState(..state, s: new_s, w: new_w))
            }
            _ -> {
              process.send(supervisor, types.RoundComplete)
              actor.continue(state)
            }
          }
        }
        PushsumMessage(message_s, message_w) -> {
          process.send(supervisor, types.RoundComplete)
          case termination_count {
            3 -> {
              actor.continue(
                PushsumGossipState(
                  ..state,
                  s: message_s +. s,
                  w: message_w +. w,
                ),
              )
            }
            _ -> {
              let new_s = s +. message_s
              let new_w = w +. message_w
              let diff = { new_s /. new_w } -. { s /. w }
              let termination_count = case diff <. 1.0e-10 {
                True -> termination_count + 1
                False -> 0
              }
              case termination_count {
                3 ->
                  process.send(supervisor, PushsumNodeConverged(new_s, new_w))
                _ -> Nil
              }
              actor.continue(
                PushsumGossipState(
                  ..state,
                  s: new_s,
                  w: new_w,
                  termination_count: termination_count,
                ),
              )
            }
          }
        }
        Shutdown -> actor.stop()
        _ -> actor.continue(state)
      }
    }
    _ -> panic as "Incorrect state type"
  }
}

fn send_to_random_neighbor(
  neighbors: List(Subject(GossipMessage)),
  s: Float,
  w: Float,
) {
  let random_neighbor_result = neighbors |> list.sample(1) |> list.first
  case random_neighbor_result {
    Ok(random_neighbor) -> {
      process.send(random_neighbor, PushsumMessage(s: s, w: w))
    }
    Error(_) -> {
      io.println("No neighbors")
    }
  }
}
