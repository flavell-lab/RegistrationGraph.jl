"""
Syncs data from local computer to a remote server and creates command files for elastix on that server.
WARNING: This program can permanently delete data if run with incorrect arguments.
# Arguments
- `edges`: List of registration problems to perform
- `data_dir_local::String`: Working directory of data on your machine.
- `data_dir_remote::String`: Working directory of data on the remote server.
- `img_prefix::String`: image prefix not including the timestamp. It is assumed that each frame's filename 
    will be, eg, `img_prefix_t0123_ch2.mhd` for frame 123 with channel=2.
- `parameter_files::Array{String,1}`: List of parameter files for elastix to use, in order of their application, 
    as stored on the remote server. These parameter files are NOT assumed to be in the working directory.
- `channel::Integer`: The channel to use for registration.
- `user::String`: Username on the server
## Optional Keyword Arguments
- `MHD_dir::String`: Directory of MHD files. Default `MHD`.
- `reg_dir::String`: Directory to place registered data. Default `Registered`.
- `log_dir::String`: Elastix output log directory. Default `log`.
- `euler_path::String`: Directory to program to do Euler registration. Defaults to Adam Atanas's version.
    If set to the empty string, Euler registration will not be performed.
- `head_path::String`: Path to a file containing locations of the worm's head.
    This must be provided if Euler registration is being used.
- `elastix_path::String`: Directory to elastix binary. Defaults to Jungsoo Kim's version.
- `cmd_dir::String`: Directory to store elastix command files. Default `elx_commands`
- `mask_dir::String`: Directory of mask files to be given to elastix. Mask files are assumed to have the same
    filenames as the corresponding MHD files. If left empty, elastix will not use a mask.
- `server::String`: Location of the server containing elastix. Default `openmind7.mit.edu`
- `use_sbatch::Bool`: Whether the command files should use `sbatch`, as opposed to being direct calls to elastix. Default true.
- `email::String`: Your email address, which the server will ping when registration finishes. If left blank, no emails will be sent.
- `cpu_per_task::Integer`: Number of CPUs to use for each elastix instance. Default 16.
- `mem::Integer`: Amount of memory in GB to use for each elastix instance. Default 4.
- `duration::Time`: Maximum amount of time elastix can run before being killed. Default 8 hours.
- `fixed_channel::Integer`: If set, the channel of the fixed frame will be this instead of `channel`.
"""
function write_sbatch_graph(edges, data_dir_local::String, data_dir_remote::String, img_prefix::String,
        parameter_files::Array{String,1}, channel::Integer, user::String;
        MHD_dir::String="MHD",
        reg_dir::String="Registered",
        log_dir::String="log",
        euler_path::String="/om/user/aaatanas/euler_registration/euler_init_keypoint_rot.py",
        head_path::String="",
        elastix_path::String="/om/user/jungsoo/Src/elastixBuild/elastix-build/bin/elastix",
        cmd_dir::String="elx_commands",
        mask_dir::String="",
        server::String="openmind7.mit.edu",
        use_sbatch::Bool=true,
        email::String="", 
        cpu_per_task::Integer=16, 
        mem::Integer=4, 
        duration::Time=Dates.Time(8,0,0),
        fixed_channel::Integer=-1)

    if fixed_channel == -1
        fixed_channel = channel
    end
    # make sure cmd_dir ends with /, otherwise rsync will not work
    if cmd_dir[end] != "/"
        cmd_dir*="/"
    end
    script_dir=joinpath(data_dir_local, cmd_dir)

    # erase previous scripts and replace them with new onces
    println("Resetting $(script_dir)...")
    rm(script_dir, recursive=true, force=true)
    create_dir(script_dir)
    duration_str = Dates.format(duration, "HH:MM:SS")

    # Euler registration requires knowing worm head location
    use_euler = (euler_path != "")
    if use_euler
        if head_path == ""
            raise(error("Head path cannot be empty if Euler registration is being used"))
        end
        println("Getting head position...")
        head_pos = read_head_pos(joinpath(data_dir_local, head_path))
    end

    log_dir = joinpath(data_dir_remote, log_dir)
    println("Writing elastix script files...")
    for edge in edges
        dir=string(edge[1])*"to"*string(edge[2])
        script_str=""
        fixed_final=lpad(edge[2],4,"0")
        moving_final=lpad(edge[1],4,"0")
        # set sbatch parameters
        if use_sbatch
            script_str *= "#!/bin/bash
            #SBATCH --job-name=elx
            #SBATCH --output=$(log_dir)/elx_$(dir).txt
            #SBATCH --nodes=1
            #SBATCH --ntasks=1
            #SBATCH --cpus-per-task=$(cpu_per_task)
            #SBATCH --time=$(duration_str)
            #SBATCH --mem=$(mem)G\n"
            if email != ""
                script_str *= "#SBATCH --mail-user=$(email)
                #SBATCH --mail-type=END\n"
            end
        end

        # make directory
        reg = joinpath(data_dir_remote, reg_dir, dir)
        script_str *= "[ ! -d $(reg) ] && mkdir $(reg)\n"

        # Euler registration
        if use_euler
            script_str *= "python $(euler_path)"*
                " "*joinpath(data_dir_remote, MHD_dir, "$(img_prefix)_t$(fixed_final)_ch$(fixed_channel).mhd")*
                " "*joinpath(data_dir_remote, MHD_dir, "$(img_prefix)_t$(moving_final)_ch$(channel).mhd")*
                " "*joinpath(data_dir_remote, reg_dir, dir, "$(dir)_euler.txt")*
                " $(head_pos[edge[2]][1]),$(head_pos[edge[2]][2])"*
                " $(head_pos[edge[1]][1]),$(head_pos[edge[1]][2])\n"
        end
        
        # elastix image and output parameters
        script_str *= elastix_path*
            " -f "*joinpath(data_dir_remote, MHD_dir, "$(img_prefix)_t$(fixed_final)_ch$(fixed_channel).mhd")*
            " -m "*joinpath(data_dir_remote, MHD_dir, "$(img_prefix)_t$(moving_final)_ch$(channel).mhd")*
            " -out "*joinpath(data_dir_remote, reg_dir, dir)
        # mask parameters
        if mask_dir != ""
            script_str *= " -fMask "*joinpath(data_dir_remote, mask_dir, "$(img_prefix)_t$(fixed_final)_ch$(fixed_channel).mhd")*
            " -mMask "*joinpath(data_dir_remote, mask_dir, "$(img_prefix)_t$(moving_final)_ch$(channel).mhd")
        end
        # initial condition parameters
        if use_euler
            script_str *= " -t0 "*joinpath(data_dir_remote, reg_dir, dir, "$(dir)_euler.txt")
        end
        # add parameter files
        for pfile in parameter_files
            script_str *= " -p $(pfile)"
        end
        # write elastix script
        script_str = mapfoldl(x->lstrip(x) * "\n", *, split(script_str, "\n"))
        filename = joinpath(script_dir, "$(dir).sh")
        open(filename, "w") do f
            write(f, script_str)
        end
    end

    println("Syncing data to server...")
    # make necessary directories on server
    run(Cmd(["ssh", "-f", "$(user)@$(server)", "[ ! -d $(data_dir_remote) ] && mkdir $(data_dir_remote)"]))
    run(Cmd(["ssh", "-f", "$(user)@$(server)", "[ ! -d $(log_dir) ] && mkdir $(log_dir)"]))
    reg = joinpath(data_dir_remote, reg_dir)
    # sync all data to the server
    run(Cmd(["ssh", "-f", "$(user)@$(server)", "[ ! -d $(reg) ] && mkdir $(reg)"]))
    run(Cmd(["rsync", "-rlDvzu", "--delete", joinpath(data_dir_local, cmd_dir*"/"), "$(user)@$(server):"*joinpath(data_dir_remote, cmd_dir)]))
    run(Cmd(["rsync", "-rlDvzu", "--delete", joinpath(data_dir_local, MHD_dir*"/"), "$(user)@$(server):"*joinpath(data_dir_remote, MHD_dir)]))
    if mask_dir != ""
        run(Cmd(["rsync", "-rlDvzu", "--delete", joinpath(data_dir_local, mask_dir*"/"), "$(user)@$(server):"*joinpath(data_dir_remote, mask_dir)]))
    end
end

"""
Syncs registration data from a remote compute server back to the local computer.

# Arguments

- `data_dir_local::String`: Working directory of the data on your machine.
- `data_dir_remote::String`: Working directory of data on the remote server.
- `user::String`: Your username on the server.

# Optional Keyword Arguments

- `reg_dir::String`: Path to registered data on server, relative to `data_dir_remote`. Default `Registered`
- `server::String`: Location of the server containing elastix. Default `openmind7.mit.edu`
"""
function sync_registered_data(data_dir_local::String, data_dir_remote::String, user::String; reg_dir="Registered", server="openmind7.mit.edu")
    create_dir(joinpath(data_dir_local, reg_dir))
    run(Cmd(["rsync", "-rlDvzu", "$(user)@$(server):"*joinpath(data_dir_remote, reg_dir*"/"), joinpath(data_dir_local, reg_dir)]))
    run(Cmd(["rsync", "-rlDvzu", "$(user)@$(server):"*joinpath(data_dir_remote, reg_dir*"/"), joinpath(data_dir_local, reg_dir)]))
end

"""
Updates parameter paths in transform parameter files, to allow `transformix` to be run on them.

# Arguments
- `problems`: Registration problems to update
- `rootpath::String`: Working directory of the data on your machine.
- `data_dir_remote::String`: Working directory of data on the remote server.
- `resolutions`: Array of number of elastix resolutions that have transform parameter files for each parameter file.

# Optional keyword arguments
- `reg_dir::String`: Directory of registered data. Default `Registered`.
"""
function fix_param_paths(problems, rootpath::String, remote_data_path::String, resolutions; reg_dir::String="Registered")
    errors = Dict()
    @showprogress for problem in problems
        errors[problem] = Dict()
        dir = joinpath(rootpath, reg_dir, "$(problem[1])to$(problem[2])")
        for i=1:length(resolutions)
            filename = joinpath(dir, "TransformParameters.$(i-1).txt")
            try
            modify_parameter_file(filename, filename, Dict(remote_data_path => rootpath); is_universal=true)
            catch e
                errors[problem][i] = e
            end
            for j=1:resolutions[i]
                filename = joinpath(dir, "TransformParameters.$(i-1).R$(j-1).txt")
                try
                    modify_parameter_file(filename, filename, Dict(remote_data_path => rootpath); is_universal=true)
                catch e
                    errors[problem][(i,j)] = e
                end
            end
        end
    end
    return errors
end
