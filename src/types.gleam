import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}

pub type SupervisorMessage {
  // StartSimulationAsync(round_limit: Int)
  StartSimulationSync
  SetNodes(List(Subject(GossipMessage)))
  ShutdownSupervisor
  RoundComplete
  GossipNodeConverged
  PushsumNodeConverged(s: Float, w: Float)
}

pub type SystemNodes {
  SystemNodes(
    nodes: Dict(Int, Subject(GossipMessage)),
    supervisor: Subject(SupervisorMessage),
  )
}

pub type SupervisorState {
  SupervisorState(
    nodes: Option(List(Subject(GossipMessage))),
    actors_received: Int,
    actors_converged: Int,
    num_nodes: Int,
    active_process: Option(process.Pid),
    algorithm: Algorithm,
  )
}

pub type GossipMessage {
  PushsumMessage(s: Float, w: Float)
  Rumor(rumor: String)
  SimulateRound(round: Int)
  SetNeighbors(
    neighbors: List(Subject(GossipMessage)),
    self: Option(Subject(GossipMessage)),
  )
  Shutdown
}

pub type Algorithm {
  Gossip
  Pushsum
}

pub type GossipState {
  RumorGossipState(
    frequency: Int,
    neighbors: List(Subject(GossipMessage)),
    rumor: Option(String),
    index: Int,
    supervisor: Subject(SupervisorMessage),
    self: Option(Subject(GossipMessage)),
  )
  PushsumGossipState(
    neighbors: List(Subject(GossipMessage)),
    s: Float,
    w: Float,
    index: Int,
    supervisor: Subject(SupervisorMessage),
    self: Option(Subject(GossipMessage)),
    termination_count: Int,
  )
}
