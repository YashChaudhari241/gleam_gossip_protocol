import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import types.{
  type GossipMessage, type SupervisorMessage, type SupervisorState, Received,
  SetNodes, ShutdownSupervisor, SimulateRound, StartSimulation, SupervisorState,
}

pub fn handle_msg_sup(state: SupervisorState, msg: SupervisorMessage) {
  case msg {
    SetNodes(nodes) -> {
      actor.continue(SupervisorState(..state, nodes: Some(nodes)))
    }
    StartSimulation(round_limit) -> {
      let worker =
        process.spawn(fn() {
          simulate_rounds(state.nodes |> option.unwrap([]), 0, round_limit)
        })
      actor.continue(SupervisorState(..state, active_process: Some(worker)))
    }
    Received -> {
      // io.println("Received: " <> int.to_string(state.actors_received + 1))
      case state.actors_received {
        x if x == state.num_nodes - 1 -> {
          io.println("Convergence reached")
          case state.active_process {
            Some(x) -> process.kill(x)
            None -> io.println("cannot find worker process")
          }
          actor.stop()
        }
        _ ->
          actor.continue(
            SupervisorState(..state, actors_received: state.actors_received + 1),
          )
      }
    }
    ShutdownSupervisor -> {
      actor.stop()
    }
  }
}

fn simulate_rounds(
  nodes: List(Subject(GossipMessage)),
  round: Int,
  round_limit: Int,
) {
  case round < round_limit {
    True -> {
      nodes
      |> list.each(fn(node) { process.send(node, SimulateRound(round)) })
      simulate_rounds(nodes, round + 1, round_limit)
    }
    False -> {
      io.println("Round limit reached.")
    }
  }
}
