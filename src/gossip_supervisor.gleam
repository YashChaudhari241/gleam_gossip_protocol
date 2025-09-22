import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
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
    // Node receives the msg for the first time
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
    // Get round progress data from actors
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
      // 65% of the nodes terminated
      case convergence_ratio >. 0.65 {
        True -> {
          io.println(
            "Convergence threshold reached. Time taken: "
            <> timestamp.difference(state.start_time, timestamp.system_time())
            |> duration.to_iso8601_string()
            <> " Ratio(s/w): "
            <> float.to_string(s /. w),
          )
          pushsum_get_stats(state.nodes |> option.unwrap([]))
          actor.stop()
          // actor.continue(
          //   SupervisorState(
          //     ..state,
          //     actors_converged: state.actors_converged + 1,
          //   ),
          // )
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

fn pushsum_get_stats(nodes: List(Subject(GossipMessage))) {
  let std_dev =
    list.map(nodes, fn(item) { process.call(item, 10, types.GetRatio) })
    |> get_std_deviation
  io.println("Std dev:" <> float.to_string(std_dev))
}

fn get_std_deviation(list_nums: List(Float)) -> Float {
  let count = int.to_float(list.length(list_nums))
  let mean = float.sum(list_nums) /. count
  let sum_of_squared_diffs =
    list_nums
    |> list.map(fn(x) {
      let diff = x -. mean
      diff *. diff
    })
    |> float.sum
  let variance = sum_of_squared_diffs /. count
  float.square_root(variance) |> result.unwrap(-1.0)
}

fn simulate_rounds_sync(nodes: List(Subject(GossipMessage))) {
  nodes
  |> list.each(fn(node) { process.send(node, SimulateRound(1)) })
}
