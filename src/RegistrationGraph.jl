module RegistrationGraph

using MHDIO, Images, Statistics, LinearAlgebra, GraphPlot, LightGraphs, FlavellBase,
        SimpleWeightedGraphs, ProgressMeter, Interact, Plots, Dates, Printf, ImageDataIO

include("make_elastix_difficulty.jl")
include("assess_registration_quality.jl")
include("run_elastix.jl")
include("make_registration_graph.jl")

export
    generate_elastix_difficulty,
    make_quality_dict,
    write_sbatch_graph,
    load_graph,
    to_dict,
    remove_frame,
    optimize_subgraph,
    output_graph,
    update_graph,
    remove_previous_registrations
end # module
