"""
Generates an elastix difficulty file based on the given heuristic.

# Arguments

- `rootpath::String`: working directory path; all other directory inputs are relative to this
- `frames`: array of frames to include in difficulty calculation
- `heuristic`: a heuristic function that evaluates "distance" betwen two frames.
    The function will be given `rootpath`, `frame1`, and `frame2 as input, so be sure its
    other parameters have been initialized correctly. It is assumed that the function outputs floating-point values.
"""
function generate_elastix_difficulty(rootpath::String, frames, difficulty_file::String, heuristic)
    n = length(frames)
    difficulty = zeros(n,n)
    @showprogress for i in 1:n
        for j in 1:n
            # skip duplicate calculations
            if j <= i
                continue
            end
            difficulty[i, j] = heuristic(rootpath, frames[i], frames[j])
        end
    end
    open(joinpath(rootpath, difficulty_file), "w") do f
        write(f, string(collect(frames))*"\n")
        write(f, replace(string(difficulty), ";"=>"\n"))
    end
    return difficulty
end
