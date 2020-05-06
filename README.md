# RegistrationGraph.jl
A collection of tools for running elastix registration. Suppose there is a set of $N$ frames to be registered, but the frames are too dissimilar to be able to ensure a quality registration for each pair of frames. In this case, it is often helpful to generate a heuristic to evaluate how similar two frames are to each other (and hence, how likely elastix will be to succeed). Once such a heuristic can be determined, registration problems can be selected to minimize difficulty and maximum path length, as a graph optimization problem. This package provides several heuristics for various registration problems, graph theory solutions for constructing the registration problem graph, and automated syncing of scripts and data to the OpenMind server.


## Frame Similarity Heuristics

## Data Filters and Background Removal


## Generating a Registration Problem Graph
As a prerequisite for this step, it is assumed that you have a heuristic for elastix registration difficulty between frames, which has been used to generate an elastix difficutly file of the appropriate format. If you're using one of the heuristics above, the formatting will already have been done; otherwise, the correct format is a comma-separated list of frames for which you have the difficulty, followed by a space/newline-separated matrix whose $[i,j]$th entry is the heuristic dissimilarity of frame $i$ to frame $j$. Both the list of frames and the matrix are allowed to use the `[` and `]` characters, which will be ignored in the parsing. Furthermore, the matrix is allowed to be triangular, and not all frames need be included in the heuristic calculation, as long as the indexing of the images is consistent with the indexing of the matrix. The frame numbers must be integers. Example for a 7-frame video of which 3 frames were discarded, and the difficulties were $d_{13} = 5$, $d_{15} = 7$, $d_{17} = 8$, $d_{35} = 1$, $d_{37} = 6$, $d_{57} = 10$:

```
[1,3,5,7]
[0.0 5.0 7.0 8.0
 0.0 0.0 1.0 6.0
 0.0 0.0 0.0 10.0
 0.0 0.0 0.0 0.0]
```

Suppose that data was saved in a file `elastix_difficulty.txt`. Then you can perform the following actions to generate a registration graph from it.

```
# loads the file into a graph
# you may want to modify the difficulty_importance parameter
# see documentation for load_graph
graph = load_graph("/path/to/elastix_difficulty.txt")

# after generating the difficulty file, you decided that frame 3 has bad data
# so you want to prevent it from being part of the registration problems
remove_frame!(graph, 3)

# generates set of registration problems from the graph
min_ind, subgraph, maximum_problem_chain = optimize_subgraph(graph)

# plot the subgraph to visualize it with the GraphPlot package
# isolated nodes are frames that will not be registered
gplot(subgraph, layout=spring_layout, arrowlengthfrac=0.03)

# saves subgraph to a text file containing a list of edges
output_graph(subgraph, "/path/to/output_file.txt")
```

## Running Elastix on Openmind
### `rsync`
A prerequisite of this code is that the `rsync` program installed on the local computer. On Mac and Linux, this should be installed by default, or be installable via the default package manager. On Windows, it is recommended to install Ubuntu (Windows Subsystem for Linux) through the Windows Store and run the code from the Ubuntu terminal.

### ssh keys
Another prerequisite of this code is that you have set up ssh keys to OpenMind. 


## Checking Elastix Quality and Regenerating the Graph
After running elastix on a set of registration problems, it is likely that most, but not all, of them will succeed. 