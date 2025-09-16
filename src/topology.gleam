// topology.gleam
import gleam/float
import gleam/int
import gleam/list

// Full topology - every node connects to every other node
pub fn full_network(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(id) {
    list.range(0, num_nodes - 1)
    |> list.filter(fn(n) { n != id })
  })
}

// Helper function to convert 1D index to 3D coordinates
fn to_xyz(id: Int, grid_size: Int) -> #(Int, Int, Int) {
  let x = id / { grid_size * grid_size }
  let yz = id % { grid_size * grid_size }
  let y = yz / grid_size
  let z = yz % grid_size
  #(x, y, z)
}

// Helper function to convert 3D coordinates back to 1D index
fn from_xyz(x: Int, y: Int, z: Int, grid_size: Int) -> Int {
  x * grid_size * grid_size + y * grid_size + z
}

// 3D Grid topology - each node connects to its 6 neighbors (up/down, left/right, front/back)
pub fn grid_3d(num_nodes: Int) -> List(List(Int)) {
  // Calculate cube root for 3D grid
  let grid_size = case int.to_float(num_nodes) {
    n -> float.power(n, 1.0 /. 3.0) |> float.ceiling |> float.round
  }

  list.range(0, num_nodes - 1)
  |> list.map(fn(id) {
    let #(x, y, z) = to_xyz(id, grid_size)

    // Generate all 6 possible neighbor coordinates
    let neighbor_coords = [
      #(x - 1, y, z),
      // left
      #(x + 1, y, z),
      // right
      #(x, y - 1, z),
      // back
      #(x, y + 1, z),
      // front
      #(x, y, z - 1),
      // down
      #(x, y, z + 1),
      // up
    ]

    neighbor_coords
    |> list.filter(fn(coord) {
      let #(nx, ny, nz) = coord
      nx >= 0
      && nx < grid_size
      && ny >= 0
      && ny < grid_size
      && nz >= 0
      && nz < grid_size
    })
    |> list.map(fn(coord) {
      let #(nx, ny, nz) = coord
      from_xyz(nx, ny, nz, grid_size)
    })
    |> list.filter(fn(neighbor_id) { neighbor_id < num_nodes })
  })
}

// Line topology - each node connects to left and right neighbors
pub fn line(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(id) {
    case id {
      0 -> [1]
      // First node: only right neighbor
      id if id == num_nodes - 1 -> [id - 1]
      // Last node: only left neighbor
      _ -> [id - 1, id + 1]
      // Middle nodes: left and right neighbors
    }
  })
}

// Imperfect 3D Grid - 3D grid + one random additional connection per node
pub fn imp3d(num_nodes: Int) -> List(List(Int)) {
  let grid_size = case int.to_float(num_nodes) {
    n -> float.power(n, 1.0 /. 3.0) |> float.ceiling |> float.round
  }

  list.range(0, num_nodes - 1)
  |> list.map(fn(id) {
    let #(x, y, z) = to_xyz(id, grid_size)

    // Get regular 3D grid neighbors (same logic as grid_3d)
    let neighbor_coords = [
      #(x - 1, y, z),
      #(x + 1, y, z),
      #(x, y - 1, z),
      #(x, y + 1, z),
      #(x, y, z - 1),
      #(x, y, z + 1),
    ]

    let grid_neighbors =
      neighbor_coords
      |> list.filter(fn(coord) {
        let #(nx, ny, nz) = coord
        nx >= 0
        && nx < grid_size
        && ny >= 0
        && ny < grid_size
        && nz >= 0
        && nz < grid_size
      })
      |> list.map(fn(coord) {
        let #(nx, ny, nz) = coord
        from_xyz(nx, ny, nz, grid_size)
      })
      |> list.filter(fn(neighbor_id) { neighbor_id < num_nodes })

    // Find nodes that are NOT grid neighbors and NOT self
    let possible_extra =
      list.range(0, num_nodes - 1)
      |> list.filter(fn(n) { n != id && !list.contains(grid_neighbors, n) })

    // Add one random extra connection (for now, just take the first available)
    // TODO: Replace with proper random selection
    case possible_extra {
      [] -> grid_neighbors
      [first, ..] -> list.append(grid_neighbors, [first])
    }
  })
}
