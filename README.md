# Asynchronous Gossip and Push-Sum Simulator

## Project Overview

This project implements a flexible simulator for two core Gossip-type algorithms—Information Propagation and Push-Sum Aggregate Computation. The simulation is built on the Gleam programming language and leverages the Erlang BEAM actor model to execute the algorithms fully asynchronously. The primary goal is to study the convergence rate of these distributed protocols under various network topologies, a critical factor in distributed system design.

## Team Members:
1. Yash Chaudhari
2. Ashmit Sharma 

## Algorithms

### Gossip Algorithm
**Purpose:** Disseminate information across a network.

**Process:**
1. Main process sends rumor to one actor
2. Each actor selects random neighbor and transmits rumor
3. Actor terminates after hearing rumor 10 times

### Push-Sum Algorithm
**Purpose:** Compute aggregate sum across distributed actors.

**State:** Each actor maintains `s` (sum) and `w` (weight)
- Initial: `s = i` (actor ID), `w = 1`
- Estimate: `s/w` at any moment

**Process:**
1. Actor sends half its `(s, w)` to random neighbor
2. Receiving actor adds incoming values to its own
3. Terminates when `s/w` changes by < 10⁻¹⁰ for 3 consecutive rounds

## Topologies

| Topology | Structure | Neighbors |
|----------|-----------|-----------|
| **Full** | Complete graph | All actors | 
| **2D** | 2D Grid | 4 (left/right/top/bottom) |
| **Line** | Linear chain | 2 (left/right) | 
| **3D Grid** | Cubic lattice | 6 (face-adjacent) | 
| **Imperfect 3D** | Grid + shortcuts | 6 grid + 1 random | 

## Usage
```
gleam run <numNodes> <topology> <algorithm>  
```

**Parameters:**
- `numNodes`: Number of actors
- `topology`: `full` | `3d` | `line` | `imp3d` | `2d`
- `algorithm`: `gossip` | `push-sum`

**Example:**
```
gleam run 1000 imp3d push-sum
```

## Observations:
- Information propagation converges in all topologies (All nodes get the rumor atleast
once)
- Pushsum Algorithm works in all topologies, the accuracy of the results depends on
the topology, (full gave best results (lowest standard deviation) but doesnt scale
well, 3d and imp3d gave the best results overall)
- For pushsum algorithm, we are detecting convergence when 65% of the nodes
converge (i.e they stop according to the termination condition)
- The ratio of s/w in pushsum algorithm approaches the mean of all the values.

## Largest Network size:

| Topology      | Algorithm Gossip | Pushsum |
|---------------|------------------|---------|
| line          | 3200             | 50000   |
| full          | 6400             | 5000    |
| 2d            | 32000            | 50000   |
| 3d            | 32000            | 50000   |
| 3d_imperfect  | 32000            | 15000   |
