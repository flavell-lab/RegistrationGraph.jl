# RegistrationGraph.jl

A collection of tools for running elastix registration. Suppose there is a set of N frames to be registered, but the frames are too dissimilar to be able to ensure a quality registration for each pair of frames. In this case, it is often helpful to generate a heuristic to evaluate how similar two frames are to each other (and hence, how likely elastix will be to succeed). Once such a heuristic can be determined, registration problems can be selected to minimize difficulty and maximum path length, as a graph optimization problem. This package provides several heuristics for various registration problems, graph theory solutions for constructing the registration problem graph, and automated syncing of scripts and data to the OpenMind server.

## Prerequisites

- This package requires you to have previously installed the `FlavellBase.jl`, `ImageDataIO.jl`, and `MHDIO.jl` packages from the `flavell-lab` github repository.
- The example code provided here assumes the `FlavellBase` and `ImageDataIO` packages have been loaded in the current Julia environment.
- [Set up an OpenMind account](https://github.mit.edu/MGHPCC/openmind/wiki/Cookbook:-Getting-started)
- Ensure that you are using a Unix-based shell. This comes by default on Mac and Linux systems, but on Windows, it is recommended to install Ubuntu (Windows Subsystem for Linux) through the Windows Store and run the code from the Ubuntu terminal.
- Install the `rsync` program if it isn't installed already
- [Set up `ssh` keys into OpenMind.](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) Leave the passphrase blank, and don't do step 4.

## Creating an elastix difficulty file from frame difference heuristics

The package `WormFeatureDetector.jl` contains a variety of heuristics that can be used to assess the difference between two frames; consult that package to find a heuristic appropriate for your situations. Once you've identified such a heuristic, you will need to condense it down to a function, giving it all the parameters in advance:

```julia
# give the heuristic all its parameters in advance, so it's a function of just three arguments
heur = (rootpath, frame1, frame2) -> heuristic(rootpath, frame1, frame2, param1, param2, param3)
# now compute elastix difficulty
generate_elastix_difficulty("/path/to/data", 1:100, "elastix_difficulty.txt", heur)
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
graph = remove_frame(graph, 3)

# generates set of registration problems from the graph
# let's say we want at least 5 edges from each node
subgraph = make_voting_subgraph(graph, 5)

# plot the subgraph to visualize it
# uses the GraphPlot package
# isolated nodes are frames that will not be registered
# NOTE: in Julia v1.4 and up, `gplot` loses the ability to plot weighted graphs
# you will need to manually copy the graph to an unweighted graph for plotting
gplot(subgraph, layout=spring_layout, arrowlengthfrac=0.03)
```

Once you're satisfied with the graph, you can save it:

```julia
# saves subgraph to a text file containing a list of edges
output_graph(subgraph, "/path/to/data/registration_problems_1.txt")
```

## Running elastix on OpenMind

### Configuring the server to run elastix

This is implemented by the `write_sbatch_graph` function, which syncs all the data from the local computer to the OpenMind server and generates files that will run elastix through `sbatch`. The data is assumed to be in the same directory, but the parameter files are allowed to be in a different directory. Example code:

```julia
# loads registration problems you previously computed from the graph
problems = load_registration_problems(["/path/to/data/registration_problems_1.txt"])

# syncs data to server and generates sbatch files for elastix
write_sbatch_graph(problems, "/path/to/data", "/path/to/data/on/openmind", "img_prefix", 
["/path/to/parameters/on/openmind/affine_parameters.txt", "/path/to/parameters/on/openmind/bspline_parameters.txt"], 2, "your_username"; head_path="head_pos.txt")

# syncs data back from server (run this after elastix registration has finished)
sync_registered_data("/path/to/data", "/path/to/data/on/openmind", "your_username")

# elastix has its transform paramete files use absolute paths - these need to be converted to the path on your machine
# replace [0,4] with resolutions of the data you're using - I have 4 incremental transform parameter files only for the second (bspline) regisration
fix_param_paths(problems, "/path/to/data", "/path/to/data/on/openmind", [0,4])
```

## Checking elastix quality

After running elastix on a set of registration problems, it is likely that many, but not all, of them will succeed. By running a quality metric, such as those implemented in the `RegistrationQualityMetrics.jl` package, the algorithm's perceived difficulty of registration pairs can be modified based on how well elastix performed in each instance. This allows the graph to be regenerated to get around the failed registrations, so that elastix can be run again. By iterating this process, it is possible to get all but a very small number of frames to be registered correctly.

The `make_quality_dict` function takes as input a list of metrics, and evaluates them on all resolutions of the registration. Note that smaller values are better (0 is perfect registration). Example code:

```julia
# initialize dictionary of functions
# usually, metrics will require other parameters, you will need to specify them here
# because all input functions must have exactly the parameters rootpath, moving, fixed, resolution
# if you're using a mask, the keyword parameter mask_dir will also be provided to the function
evaluation_functions = Dict()
evaluation_functions["metric1"] = (rootpath, moving, fixed, resolution) -> compute_metric1(rootpath, moving, fixed, resolution, param1, param2, param3)
evaluation_functions["metric2"] = (roopath, moving, fixed, resolution) -> compute_metric2(rootpath, moving, fixed, resolution, param4, param5)

# now, compute and output quality dictionary
q_dict, best_reg = make_quality_dict("/path/to/data", "registration_problems_1.txt", "registration_quality_1.txt", evaluation_functions, "metric1", [(0,0), (0,1), (1,0), (1,1)])
```

## Extracting Data

See the package `ExtractRegisteredData.jl`
