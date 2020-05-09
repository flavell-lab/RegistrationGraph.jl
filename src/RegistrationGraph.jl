module RegistrationGraph

using MHDIO, Images, Statistics, LinearAlgebra, GraphPlot, LightGraphs, 
        SimpleWeightedGraphs, ProgressMeter, Interact, Plots, Dates, Printf

include("make_elastix_difficulty.jl")
include("assess_registration_quality.jl")
include("run_elastix.jl")
include("make_registration_graph.jl")

export
    generate_elastix_difficulty,
    make_quality_dict,
    load_registration_problems,
    write_sbatch_graph,
    load_graph,
    remove_frame!,
    optimize_subgraph,
    output_graph,
    update_graph,
    update_registration_problems,
    make_final_graph
end # module
