"""
Computes maximum intensity projection of `array` along the dimensions `dims`
"""
function maxprj(array; dims=3)
    dropdims(maximum(array; dims=dims), dims=dims)
end

"""
Creates directory `dirpath` if it doesn't exist
"""
function create_dir(dirpath::String)
    if !isdir(dirpath)
        mkdir(dirpath)
    end
end

"""
Aligns the points `headpt` and `tailpt` of curve 2 to match curve 1, and returns the transformed curve 2.
Translates, rotates, and scales all other curve-points accordingly.
# Arguments:
- `curve1_x`: Array of x-coordinates of first worm
- `curve1_y`: Array of y-coordinates of first worm
- `curve2_x`: Array of x-coordinates of second worm
- `curve1_y`: Array of y-coordinates of second worm
- `headpt::Integer`: First position from head (in index of curves) to be aligned. Default 4.
- `tailpt::Integer`: Second position from head (in index of curves) to be aligned. Default 7.
"""
function align(curve1_x, curve1_y, 
        curve2_x, curve2_y; headpt::Integer=4, tailpt::Integer=7)
    # Make tip of the nose be the origin
    c1_x = curve1_x .- curve1_x[headpt]    
    c1_y = curve1_y .- curve1_y[headpt]
    c2_x = curve2_x .- curve2_x[headpt]    
    c2_y = curve2_y .- curve2_y[headpt]
    # compute rotation angle
    theta_1 = atan(c1_y[tailpt]/c1_x[tailpt])
    theta_2 = atan(c2_y[tailpt]/c2_x[tailpt])
    delta_theta = theta_1 - theta_2
    # compute scaling factor
    scale_1 = sqrt(c1_x[tailpt]^2 + c1_y[tailpt]^2)
    scale_2 = sqrt(c2_x[tailpt]^2 + c2_y[tailpt]^2)
    scale = scale_1/scale_2
    # transform curve 2
    M_rot = scale * [cos(delta_theta) -sin(delta_theta); sin(delta_theta) cos(delta_theta)]
    c2 = M_rot * transpose([c2_x c2_y])
    # we need to rotate by an additional pi
    if abs(c2[1,tailpt] - c1_x[tailpt]) > 1
        c2 = -c2
    end
    # add back curve 1's origin-position
    return (c2[1,:] .+ curve1_x[headpt], c2[2,:] .+ curve1_y[headpt])
end

"""
Computes the difficulty of an elastix transform
using the heuristic that more worm-unbending is harder.
# Arguments:
- `x1_c`: Array of x-coordinates of first worm
- `y1_c`: Array of y-coordinates of first worm
- `x2_c`: Array of x-coordinates of second worm
- `y2_c`: Array of y-coordinates of second worm
- `headpt::Integer`: First position from head (in index of curves) to be aligned. Default 4.
- `tailpt::Integer`: Second position from head (in index of curves) to be aligned. Default 7.
"""
function elastix_difficulty(x1_c, y1_c, x2_c, y2_c;
        headpt::Integer=4, tailpt::Integer=7)
    x2, y2 = align(x1_c, y1_c, x2_c, y2_c; headpt=headpt, tailpt=tailpt)
    delta = sum(map(sqrt,(x2 .- x1_c).^2 + (y2 .- y1_c).^2))
    return delta
end

"""
Reads the worm head position from the file `head_path::String`.
Returns a dictionary mapping frame => head position of the worm at that frame.
"""
function read_head_pos(head_path::String)
    head_pos = Dict()
    open(head_path) do f
        for line in eachline(f)
            l = split(line)
            head_pos[parse(Int16, l[1])] = Tuple(map(x->parse(Float64, x), l[2:end]))
        end
    end
    return head_pos
end

"""
Generates an elastix difficulty file based on the worm curvature heuristic.
Requires that the data be filtered in some way (eg: total-variation filtering),
and that the head position of the worm is known in each frame.
# Arguments:
- `rootpath::String`: working directory path; all other directory inputs are relative to this
- `mhd_path::String`: path to MHD image files
- `head_path::String`: path to a file containing positions of the worm's head at each frame.
- `img_prefix::String`: image prefix not including the timestamp. It is assumed that each frame's filename
    will be, eg, `img_prefix_t0123_ch2.mhd` for frame 123 with channel=2.
- `channel::Integer`: channel being used. Can be entered as any data type.
- `frames`: which frames should be included in the difficulty calculation.
    (This can, for instance, be used to exclude frames where the worm is not in the field of view.)
- `difficulty_file::String`: path to file to save elastix difficulty.
- `figure_save_path`: Path to save figures of worm curvature. If left at its default value `nothing`, figures will not be generated.
## Heuristic parameters (optional):
- `downscale::Integer`: log2(factor) by which to downscale the image before processing. Default 3 (ie: downscale by a factor of 8)
- `num_points::Integer`: number of points (not including head) in generated curve. Default 9.
- `headpt::Integer`: First position from head (in index of curves) to be aligned. Default 4.
- `tailpt::Integer`: Second position from head (in index of curves) to be aligned. Default 7.
"""
function generate_elastix_difficulty_wormcurve(rootpath::String, mhd_path::String, head_path::String,
        img_prefix::String, channel::Integer, frames, difficulty_file::String,
        figure_save_path=nothing; downscale::Integer=3, num_points::Integer=9, headpt::Integer=4, tailpt::Integer=7)
    len = length(frames)
    difficulty = zeros(len, len)
    println("Loading images...")
    imgs = []
    @showprogress for i in frames
        path_i = joinpath(rootpath, mhd_path, img_prefix*"_t"*string(i, pad=4)*"_ch$(channel).mhd")
        push!(imgs, Float64.(maxprj(read_img(MHD(path_i)), dims=3)))
    end
    println("Getting worm curves")
    curves = []
    head_pos = read_head_pos(joinpath(rootpath, head_path))
    @showprogress for i in 1:len
        x_c = nothing
        y_c = nothing
        x_c, y_c = find_curve(imgs[i], downscale, head_pos[frames[i]]./2^downscale, num_points)
        if figure_save_path != nothing
            create_dir(joinpath(rootpath, figure_save_path))
            f = figure();
            imshow(transpose(imgs[i]), cmap="gray");
            axis("off"); scatter(x_c.-1, y_c.-1,color="red",s=10); scatter(x_c[1].-1, y_c[1].-1, color="blue");
            savefig(joinpath(rootpath, figure_save_path, "$(frames[i]).png"));
            close(f)
        end
        push!(curves, (x_c, y_c))
    end
        
    println("Computing elastix difficulty...")
    @showprogress for i in 1:len
        for j in 1:len
            # skip duplicate calculations
            if j <= i
                continue
            end
            difficulty[i, j] = elastix_difficulty(curves[i][1], curves[i][2], curves[j][1], curves[j][2], headpt=headpt, tailpt=tailpt)
        end
    end

    println("Writing output...")
    open(joinpath(rootpath, difficulty_file), "w") do f
        write(f, string(frames)*"\n")
        write(f, replace(string(difficulty), ";"=>"\n"))
    end
end