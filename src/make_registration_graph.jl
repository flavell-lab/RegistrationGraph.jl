""" 
Computes the minimum path between a node and all other nodes using Dijkstra's algorithm.
# Arguments
- `graph::SimpleWeightedGraph`: a graph represented as a weighted adjacency matrix
- `node::Integer`: a node in the graph, represented as an index into `adj`
# Returns:
- `dist::Dict`: a dictionary of distances from each vertex to the `node` vertex
- `paths::Dict`: a dictionary of shortest paths from each vertex to the `node` vertex
"""
function shortest_paths(graph::SimpleWeightedGraph, node::Integer)
    dist = Dict()
    paths = Dict()
    unvisited = collect(1:size(adj)[1])
    # initialize distances
    for i=1:size(adj)[1]
        dist[i] = Inf
        paths[i] = []
    end
    dist[node] = 0
    paths[node] = [node]
    while length(unvisited) > 0
        min_d, idx = findmin([dist[i] for i in unvisited])
        if min_d == Inf
            break
        end
        current = unvisited[idx]
        for i in unvisited
            new_dist = dist[current] + adj[current, i]
            if new_dist < dist[i]
                dist[i] = new_dist
                paths[i] = [paths[current]; i]
            end
        end
        unvisited = filter(x->(x!=current), unvisited)
    end
    return (dist, paths)
end

"""
Converts a `graph::SimpleWeightedGraph` into an adjacency dictionary
node => Dict({neighbor1 => weight1, neighbor2=> weight2, ...})
"""
function to_dict(graph::SimpleWeightedGraph)
    dict = Dict()
    for edge in edges(graph)
        if !(src(edge) in keys(dict))
            dict[src(edge)] = Dict()
        end
        if !(dst(edge) in keys(dict))
            dict[dst(edge)] = Dict()
        end
        dict[src(edge)][dst(edge)] = weight(edge)
        dict[dst(edge)][src(edge)] = weight(edge)
    end
    return dict
end


"""
Finds the minimum node of a graph, which has the smallest average shortest path length
to each other node in that graph. Unconnected nodes are counted as having a path length equal to the
highest edge weight.
# Parameters
- `graph::SimpleWeightedGraph`: a graph
# Returns:
- `min_node::Integer`: the minimum node
- `subgraph::SimpleWeightedDiGraph`: an unweighted graph whose edges consist of shortest paths from the minimum node of the original graph to other nodes.
- `maximum_problem_chain::Integer`: the number of vertices in the longest chain of registration problems in the subgraph.
This graph is directed, and only has edges going away from the minimum node.
"""
function optimize_subgraph(graph::SimpleWeightedGraph)
    dist = []
    paths = []
    max_val = maximum(map(e->(weight(e) == Inf ? 0 : weight(e)), edges(graph)))
    # get all shortest paths
    for i=1:nv(graph)
        paths_i = dijkstra_shortest_paths(graph, i)
        push!(dist, paths_i.dists)
        push!(paths, enumerate_paths(paths_i))
    end
    # find node with minimum shortest paths
    min_avg, min_ind = findmin([sum(map(x->(x > max_val) ? max_val : x, d)) for d in dist])
    min_paths = paths[min_ind]
    subgraph = SimpleWeightedDiGraph(nv(graph))
    weight_dict = to_dict(graph)
    for path in min_paths
        for i=2:length(path)
            add_edge!(subgraph, path[i-1], path[i], weight_dict[path[i]][path[i-1]])
        end
    end
    return (min_ind, subgraph, maximum([length(path) for path in min_paths]))
end

"""
Loads an adjacency matrix from a file and stores it as a graph.
You can specify a function to apply to each weight.
This is often helpful in cases where the heuristic obeys the triangle inequality,
to avoid the function from generating a star graph and mostly ignoring the heuristic.
By default, the function is x->x^1.05, which allows the algorithm to
split especially difficult registration problems into many steps.
If this results in too many failed registrations, try increasnig the difficulty_importance parameter;
conversely, if there is too much error accumulation over long chains of registrations, try decreasing it.
# Arguments
- `elastix_difficulty::String`: a text file containing a list of frames and an adjacency matrix.
- `func` (optional): a function to apply to each element of the adjacency matrix
- `difficulty_importance`: if `func` is not provided, it will be set to `x->x^(1+difficulty_importance)`
Returns a graph `graph::SimpleWeightedGraph` storing the adjacency matrix.
"""
function load_graph(elx_difficulty::String; func=nothing, difficulty_importance::Real=0.05)
    graph = nothing
    imgs = nothing
    if func == nothing
        func = x->x^(1+difficulty_importance)
    end
    open(elx_difficulty) do f
        count = 0
        for line in eachline(f)
            if count == 0
                # the array of images
                imgs = map(x->parse(Int64, x), split(replace(line, r"\[|\]|Any" => ""), ", "))
                # number of nodes is the highest frame number
                graph = SimpleWeightedGraph(maximum(imgs))
            else
                for e in enumerate(map(x->func(parse(Float64, x)), split(replace(line, r"\[|\]" => ""))))
                    if e[2] != Inf && e[2] != 0
                        # difficulty array may have skipped already-deleted frames
                        # make sure to index into imgs to get accurate frame numbers
                        add_edge!(graph, imgs[count], imgs[e[1]], e[2])
                    end
                end
            end
            count = count + 1
        end
    end
    return graph
end
 
"""
Outputs `graph::SimpleWeightedDiGraph` to an output file `outfile` containing a list of edges in `graph`.
"""
function output_graph(subgraph::SimpleWeightedDiGraph, outfile::String)
    open(outfile, "w") do f
        for edge in edges(subgraph)
            write(f, string(Int16(src(edge)))*" "*string(Int16(dst(edge)))*"\n")
        end
    end
end

"""
Deletes a problematic `frame::Integer` from a graph `graph::SimpleWeightedGraph` without changing frame indices.
"""
function remove_frame!(graph::SimpleWeightedGraph, frame::Integer)
    # set weights of all edges from the frame to infinity
    # thereby preventing it from being included in any shortest path
    for n in neighbors(graph, frame)
        add_edge!(graph, frame, n, Inf)
    end
end


"""
Recomputes the difficulty graph based on registration quality data.
Returns a new graph where difficulties of registration problems are scaled by the quality metric.
# Arguments
- `reg_quality_arr::Array{String,1}` is an array of filenames containing registration quality data.
- `graph::SimpleWeightedGraph` is the difficulty graph to be updated
- `metric::String` is which quality metric to use to update the graph
"""
function update_graph(reg_quality_arr::Array{String,1}, graph::SimpleWeightedGraph, metric::String)
    new_graph = copy(graph)
    d = to_dict(graph)
    for reg_quality in reg_quality_arr
        open(reg_quality, "r") do f
            first = true
            idx = 0
            for line in eachline(f)
                data = split(line)
                if first
                    idx = findfirst(data.==metric)
                    first = false
                    continue
                end
                moving,fixed = map(x->parse(Int32, x), split(data[1], "to"))
                metric_val = parse(Float64, data[idx])
                new_difficulty = d[moving][fixed] * metric_val
                add_edge!(new_graph, moving, fixed, new_difficulty)
            end
        end
    end
    return new graph
end

"""
Loads a set of registration problems from a set of files `edge_file::Array{String, 1}` into an array
"""
function load_registration_problems(edge_files::Array{String,1})
    reg_problems = []
    for edge_file in edge_files
        open(edge_file) do f
            for line in eachline(f)
                push!(reg_problems, Tuple(map(x->parse(Int64, x), split(line))))
            end
        end
    end
    return reg_problems
end

"""
Removes previous registrations from the subgraph. 
"""
function remove_previous_registrations(subgraph::SimpleWeightedDiGraph, previous_problems::Array{String,1})
    previous_problems = []
    for previous_reg in previous_problems
        append!(previous_problems, load_registration_problems(previous_reg))
    end
    subgraph_purged = SimpleWeightedDiGraph(nv(subgraph))
    for edge in edges(subgraph)
        if !((src(edge), dst(edge)) in previous_problems)
            add_edge!(subgraph_purged, src(edge), dst(edge), weight(edge))
        end
    end
    return subgraph_purged
end
