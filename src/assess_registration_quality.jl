"""
Computes the quality of registration using NCC, nearest-neighbors distance between centroids, and manual annotation.
Returns a dictionary of registration quality values for each resolution, and another dictionary of the best resolution for each problem.
Outputs a text file containing registration quality values at the best resolution.
It is assumed that smaller values are better for the metrics.
# Arguments
- `rootpath::String`: working directory path; all other directory inputs are relative to this
- `problem_path::String`: path to a file containing list of elastix registration problems
- `outfile::String`: path to output file for dictionary
- `evaluation_functions::Dict`: dictionary of metric names to functions that evaluate elastix quality on a pair of images.
    The evaluation functions will be given `rootpath`, `fixed`, `moving`, `resolution`, and possibly `mask_dir` as input, so be sure their
    other parameters have been initialized correctly. It is assumed that the functions output floating-point metric values.
- `selection_metric::String`: which metric should be used to select the best registration out of the set of possible registrations
- `resolutions`: an array of resolution values to be using. Each value is represented as a tuple `(i,j)`, where `i` is the number of parameter file
    to use and `j` is the resolution for registrations using that parameter file. Both are 0-indexed.
## Optional Keyword Arguments
- `mask_dir::String`: directory to a mask file. Statistics will not be computed on regions outside the mask.
    If left blank, no mask will be used or passed to the evaluation functions.
"""
function make_quality_dict(rootpath::String, problem_path::String, outfile::String, evaluation_functions::Dict,
        selection_metric::String, resolutions; mask_dir::String="")
    dict = Dict()
    best_reg = Dict()
    func_names = keys(evaluation_functions)
    open(joinpath(rootpath, problem_path), "r") do f
        open(joinpath(rootpath, outfile), "w") do quality
            write(quality, rpad("Registration", 16))
            for name in func_names
                write(quality, rpad(name, 13))
            end
            write(quality, "\n")
            for prob in eachline(f)
                moving,fixed = map(x->parse(Int16, x), split(prob, " "))
                best_resolution = nothing
                best_result = Inf
                for resolution in resolutions
                    for metric in func_names
                        func = evaluation_functions[metric]
                        if mask_dir == ""
                            result = func(rootpath, moving, fixed, resolution)
                        else
                            result = func(rootpath, moving, fixed, resolution, mask_dir)
                        end
                        dict[(moving,fixed)][resolution][metric] = result
                        if metric == selection_metric && result < best_result
                            best_result = result
                            best_resolution = resolution
                        end
                    end
                end
                for metric in func_names
                    write(quality, rpad(@sprintf("%.2f", dict[(moving,fixed)][best_resolution][metric]), 13))
                end
                write(quality, "\n")
                best_reg[prob] = best_resolution
            end
        end
    end
    return dict, best_reg
end

