pub type GossipMessage {
  Rumor(msg: String)
  Shutdown
}

pub type GossipState {
  GossipState(frequency: Int, neighbors: Int)
}

pub fn handle_message_gossip(msg: GossipMessage) {
  todo
}
