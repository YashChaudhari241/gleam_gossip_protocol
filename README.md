# Gossip protocol

Team Members:
1. Yash Chaudhari (UFID: 2260-3734)
2. Ashmit Sharma (UFID: 2838-1009)

What’s Working:
- Information propagation converges in all topologies (All nodes get the rumor atleast
once)
- Pushsum Algorithm works in all topologies, the accuracy of the results depends on
the topology, (full gave best results (lowest standard deviation) but doesnt scale
well, 3d and imp3d gave the best results overall)
- For pushsum algorithm, we are detecting convergence when 65% of the nodes
converge (i.e they stop according to the termination condition)
- The ratio of s/w in pushsum algorithm approaches the mean of all the values.

Largest Network size:

| Topology      | Algorithm Gossip | Pushsum |
|---------------|------------------|---------|
| line          | 3200             | 50000   |
| full          | 6400             | 5000    |
| 2d            | 32000            | 50000   |
| 3d            | 32000            | 50000   |
| 3d_imperfect  | 32000            | 15000   |
