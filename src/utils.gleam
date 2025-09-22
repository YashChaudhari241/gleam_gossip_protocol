import clip.{type Command}
import clip/arg

pub type Args {
  Args(num_nodes: Int, topology: String, algorithm: String)
}

//Define Command line args
pub fn command() -> Command(Args) {
  clip.command({
    use num_nodes <- clip.parameter
    use topology <- clip.parameter
    use algorithm <- clip.parameter
    Args(num_nodes, topology, algorithm)
  })
  |> clip.arg(
    arg.new("num_nodes")
    |> arg.int
    |> arg.help("Number of nodes in the system"),
  )
  |> clip.arg(
    arg.new("topology") |> arg.help("Topology: 2d, full, line, 3d or imp3d"),
  )
  |> clip.arg(
    arg.new("algorithm")
    |> arg.default("gossip")
    |> arg.help("algorithm: either gossip or push-sum"),
  )
}
