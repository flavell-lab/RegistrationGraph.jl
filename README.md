# RegistrationGraph.jl
A collection of tools for running elastix registration. Suppose there is a set of N frames to be registered, but the frames are too dissimilar to be able to ensure a quality registration for each pair of frames. In this case, it is often helpful to generate a heuristic to evaluate how similar two frames are to each other (and hence, how likely elastix will be to succeed). Once such a heuristic can be determined, registration problems can be selected to minimize difficulty and maximum path length, as a graph optimization problem. This package provides several heuristics for various registration problems, graph theory solutions for constructing the registration problem graph, and automated syncing of scripts and data to the OpenMind server.

## Frame similarity heuristics
### Worm curvature similarity heuristic
This heuristic (implemented by the `generate_elastix_difficulty_wormcurve` method) posits that two frames are similar to each other if the worm's curvature is similar, as this would result in a smaller amount of bending. It computes an estimate for the worm's centerline based on the images, and outputs its centerline fits as images which can be inspected for errors.

This heuristic requires data that has nuclear-localized fluorescent proteins in enough neurons to get an estimate of the worm shape, and has already been filtered (eg by the `GPUFilter.jl` package). It also requires you to have previously determined the worm's head location, such as in the `WormFeatureDetector.jl` package.

Example code:

```julia
generate_elastix_difficulty_wormcurve("/path/to/data", "MHD", "head_pos.txt", "img_prefix", 2, 1:100, "elastix_difficulty.txt", "worm_curves")
```

### HSN and nerve ring location heuristic
This heuristic (implemented by the `generate_elastix_difficulty_HSN_NR` method) tries to identify frames with similar HSN and nerve ring locations to be registered together. It only works on data taken with a non-nuclear-localized fluorescent protein expressed only in HSN, and it also requires you to have previously identified the HSN and nerve ring locations in each frame, which is implemented in the `WormFeatureDetector.jl` package.

Example code:

```julia
generate_elastix_difficulty_HSN_NR("/path/to/data", "hsn_locs.txt", "nr_locs.txt", 1:100, "elastix_difficulty.txt")
```


## Generating a registration problem graph
As a prerequisite for this step, it is assumed that you have a heuristic for elastix registration difficulty between frames, which has been used to generate an elastix difficutly file of the appropriate format. If you're using one of the heuristics above, the formatting will already have been done; otherwise, the correct format is a comma-separated list of frames for which you have the difficulty, followed by a space/newline-separated matrix whose [i,j]th entry is the heuristic dissimilarity of frame i to frame j. Both the list of frames and the matrix are allowed to use the `[` and `]` characters, which will be ignored in the parsing. Furthermore, the matrix is allowed to be triangular, and not all frames need be included in the heuristic calculation, as long as the indexing of the images is consistent with the indexing of the matrix. The frame numbers must be integers. Example for a 7-frame video of which 3 frames were discarded:

```text
[1,3,5,7]
[0.0 5.0 7.0 8.0
 0.0 0.0 1.0 6.0
 0.0 0.0 0.0 10.0
 0.0 0.0 0.0 0.0]
```

Suppose that data was saved in a file `elastix_difficulty.txt`. Then you can perform the following actions to generate a registration graph from it.

```julia
# loads the file into a graph
# you may want to modify the difficulty_importance parameter
# see documentation for load_graph for more details
graph = load_graph("/path/to/data/elastix_difficulty.txt")

# after generating the difficulty file, you decided that frame 3 has bad data
# so you want to prevent it from being part of the registration problems
remove_frame!(graph, 3)

# generates set of registration problems from the graph
min_ind, subgraph, maximum_problem_chain = optimize_subgraph(graph)

# plot the subgraph to visualize it with the GraphPlot package
# isolated nodes are frames that will not be registered
gplot(subgraph, layout=spring_layout, arrowlengthfrac=0.03)

# saves subgraph to a text file containing a list of edges
output_graph(subgraph, "/path/to/data/registration_problems.txt")
```

## Running elastix on OpenMind

### Prerequisites

- [Set up an OpenMind account](https://github.mit.edu/MGHPCC/openmind/wiki/Cookbook:-Getting-started)
- Ensure that you are using a Unix-based shell. This comes by default on Mac and Linux systems, but on Windows, it is recommended to install Ubuntu (Windows Subsystem for Linux) through the Windows Store and run the code from the Ubuntu terminal.
- Install the `rsync` program if it isn't installed already
- [Set up `ssh` keys into OpenMind.](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) Leave the passphrase blank, and don't do step 4.

### Configuring the server to run elastix
This is implemented by the `write_sbatch_graph` function, which syncs all the data from the local computer to the OpenMind server and generates files that will run elastix through `sbatch`. The data is assumed to be in the same directory, but the parameter files are allowed to be in a different directory. Example code:

```julia
# loads registration problems you previously computed from the graph
problems = load_registration_problems("/path/to/data/registration_problems.txt")

# syncs data to server and generates sbatch files for elastix
write_sbatch_graph(problems, "/path/to/data", "/path/to/data/on/openmind", "img_prefix", 
["/path/to/parameters/on/openmind/affine_parameters.txt", "/path/to/parameters/on/openmind/bspline_parameters.txt"], 2, "your_username"; head_path="head_pos.txt")
```

## Checking elastix quality and regenerating the graph
After running elastix on a set of registration problems, it is likely that many, but not all, of them will succeed. 

### Manually assessing registration quality
