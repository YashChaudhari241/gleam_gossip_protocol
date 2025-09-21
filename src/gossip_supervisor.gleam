import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/time/duration
import gleam/time/timestamp
import types.{
  type GossipMessage, type SupervisorMessage, type SupervisorState,
  GossipNodeConverged, PushsumNodeConverged, RoundComplete, SetNodes,
  ShutdownSupervisor, SimulateRound, StartSimulationSync, SupervisorState,
}

pub fn handle_msg_sup(state: SupervisorState, msg: SupervisorMessage) {
  case msg {
    SetNodes(nodes) -> {
      actor.continue(SupervisorState(..state, nodes: Some(nodes)))
    }
    StartSimulationSync -> {
      simulate_rounds_sync(state.nodes |> option.unwrap([]))
      actor.continue(
        SupervisorState(..state, start_time: timestamp.system_time()),
      )
    }
    GossipNodeConverged -> {
      case state.actors_converged {
        x if x == state.num_nodes - 1 -> {
          io.println(
            "Convergence reached. Time taken: "
            <> timestamp.difference(state.start_time, timestamp.system_time())
            |> duration.to_iso8601_string(),
          )
          actor.stop()
        }
        _ ->
          actor.continue(
            SupervisorState(
              ..state,
              actors_converged: state.actors_converged + 1,
            ),
          )
      }
    }
    RoundComplete -> {
      case state.actors_received {
        x if x == state.num_nodes - 1 -> {
          simulate_rounds_sync(state.nodes |> option.unwrap([]))
          actor.continue(SupervisorState(..state, actors_received: 0))
        }
        _ ->
          actor.continue(
            SupervisorState(..state, actors_received: state.actors_received + 1),
          )
      }
    }
    PushsumNodeConverged(s, w) -> {
      // io.println(
      //   "Node Converged s: "
      //   <> float.to_string(s)
      //   <> " w: "
      //   <> float.to_string(w)
      //   <> " ratio: "
      //   <> float.to_string(s /. w)
      //   <> " Total: "
      //   <> int.to_string(state.actors_converged),
      // )
      let convergence_ratio =
        int.to_float(state.actors_converged) /. int.to_float(state.num_nodes)
      case convergence_ratio >. 0.65 {
        True -> {
          io.println(
            "Convergence threshold reached. Time taken: "
            <> timestamp.difference(state.start_time, timestamp.system_time())
            |> duration.to_iso8601_string()
            <> " Ratio(s/w): "
            <> float.to_string(s /. w),
          )
          actor.stop()
        }
        False ->
          actor.continue(
            SupervisorState(
              ..state,
              actors_converged: state.actors_converged + 1,
            ),
          )
      }
    }
    ShutdownSupervisor -> {
      actor.stop()
    }
  }
}

fn simulate_rounds_sync(nodes: List(Subject(GossipMessage))) {
  nodes
  |> list.each(fn(node) { process.send(node, SimulateRound(1)) })
}
