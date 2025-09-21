import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}

pub type SupervisorMessage {
  StartSimulation(round_limit: Int)
  SetNodes(List(Subject(GossipMessage)))
  ShutdownSupervisor
  Received
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
    num_nodes: Int,
    active_process: Option(process.Pid),
  )
}

pub type GossipMessage {
  Rumor(rumor: String)
  SimulateRound(round: Int)
  SetNeighbors(
    neighbors: List(Subject(GossipMessage)),
    self: Option(Subject(GossipMessage)),
  )
  Shutdown
}

pub type GossipState {
  GossipState(
    frequency: Int,
    neighbors: List(Subject(GossipMessage)),
    rumor: Option(String),
    index: Int,
    supervisor: Subject(SupervisorMessage),
    self: Option(Subject(GossipMessage)),
  )
}
