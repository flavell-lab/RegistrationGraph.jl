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
- `head_rotate_path::String`: Directory to program to do Euler registration. Defaults to Adam Atanas's version.
    If set to the empty string, Euler registration will not be performed.
- `euler_logfile::String`: Filename of Euler output. Default `euler.log`
- `head_path::String`: Path to a file containing locations of the worm's head.
    This must be provided if Euler registration is being used.
- `elastix_path::String`: Directory to elastix binary. Defaults to Jungsoo Kim's version.
- `cmd_dir::String`: Directory to store elastix command files. Default `elx_commands`,
- `cmd_dir_array::String`: Directory to store sbatch arrays that run elastix command files.
    If set to the empty string, no arrays will be generated. Default `elx_commands_array`
- `job_name::String`: Name of array job files, subscripted with an index. Default `elx`.
- `array_size::Integer`: Number of commands per array. Default 499.
- `run_elx_command::String`: Path to a bash script on OpenMind that runs a script from a line in a text file list of scripts
- `clear_cmd_dir::Bool`: Whether to clear command directory on OpenMind before syncing. Default true.
- `mask_dir::String`: Directory of mask files to be given to elastix. Mask files are assumed to have the same
    filenames as the corresponding MHD files. If left empty, elastix will not use a mask.
- `server::String`: Location of the server containing elastix. Default `openmind7.mit.edu`
- `use_sbatch::Bool`: Whether the command files should use `sbatch`, as opposed to being direct calls to elastix. Default true.
- `email::String`: Your email address, which the server will ping when registration finishes. If left blank, no emails will be sent.
- `cpu_per_task::Integer`: Number of CPUs to use for each elastix instance. Default 16.
- `mem::Integer`: Amount of memory in GB to use for each elastix instance. Default 1.
- `duration::Time`: Maximum amount of time elastix can run before being killed. Default 1 hour.
- `fixed_channel::Integer`: If set, the channel of the fixed frame will be this instead of `channel`.
- `data_dir_local_moving::String`: If set, the directory of the moving data (if different from that of the fixed data)
- `data_dir_remote_moving::String`: If set, the directory of the moving data (if different from that of the fixed data)
- `img_prefix_moving::String`: If set, the image prefix of the moving data (if different from that of the fixed data)
"""
function write_sbatch_graph(edges, param_path::Dict, param::Dict, get_basename::Function;
        clear_cmd_dir::Bool=true,
        cpu_per_task_key::String="cpu_per_task", 
        memory_key::String="memory", 
        duration_key::String="duration",
        job_name_key::String="job_name"
        fixed_channel_key::String="ch_marker",
        moving_channel_key::String="ch_marker",
        data_dir_fixed_key::String="path_root_process",
        data_dir_moving_key::String="path_root_process",
        head_dir_fixed_key::String="path_head_pos",
        head_dir_moving_key::String="path_head_pos",
        data_dir_remote_fixed_key::String="path_om_data",
        data_dir_remote_moving_key::String="path_om_data",
        MHD_dir_fixed_key::String="path_dir_mhd_filt",
        MHD_dir_moving_key::String="path_dir_mhd_filt",
        mask_dir_fixed_key::String="path_dir_mask",
        mask_dir_moving_key::String="path_dir_mask",
        reg_dir_fixed_key::String="path_dir_reg",
        reg_dir_moving_key::String="path_dir_reg",
        path_head_rotate_key::String="path_head_rotate",
        parameter_files_key::String="parameter_files",
        get_basename_moving::Union{Function,Nothing}=nothing)

    data_dir_local = param_path[data_dir_fixed_key]
    data_dir_local_moving = param_path[data_dir_moving_key]
    data_dir_remote = param_path[data_dir_remote_fixed_key]
    data_dir_remote_moving = param_path[data_dir_remote_moving_key]
    MHD_dir_local = param_path[MHD_dir_fixed_key]
    MHD_dir_local_moving = param_path[MHD_dir_moving_key]
    MHD_dir_remote = replace(MHD_dir_local, data_dir_local => data_dir_remote)
    MHD_dir_remote_moving = replace(MHD_dir_local_moving, data_dir_local_moving => data_dir_remote_moving)
    mask_dir_local = param_path[mask_dir_fixed_key]
    mask_dir_local_moving = param_path[mask_dir_moving_key]
    if mask_dir_local !== nothing
        mask_dir_remote = replace(mask_dir_local, data_dir_local => data_dir_remote)
    else
        mask_dir_remote = nothing
    end
    if mask_dir_local_moving !== nothing
        mask_dir_remote_moving = replace(mask_dir_local_moving, data_dir_local => data_dir_remote_moving)
    else
        mask_dir_remote_moving = nothing
    end
    reg_dir_local = param_path[reg_dir_fixed_key]
    reg_dir_local_moving = param_path[reg_dir_moving_key]
    reg_dir_remote = replace(reg_dir_local, data_dir_local => data_dir_remote)
    reg_dir_remote_moving = replace(reg_dir_local_moving, data_dir_local => data_dir_remote_moving)
    head_dir = param_path[head_dir_fixed_key]
    head_dir_moving = param_path[head_dir_moving_key]

    if get_basename_moving === nothing
        get_basename_moving = get_basename
    end

    cmd_dir_local = param_path["path_dir_cmd"]
    cmd_dir_remote = replace(cmd_dir_local, data_dir_local => data_dir_remote)
    cmd_dir_array_local = param_path["path_dir_cmd_array"]
    if cmd_dir_array_local !== nothing
        cmd_dir_array_remote = replace(cmd_dir_array_local, data_dir_local => data_dir_remote)
    else
        cmd_dir_array_remote = nothing
    end
    head_rotate_path = param_path[path_head_rotate_key]
    log_dir = param_path["path_dir_log"]
    run_elx_command = param_path["path_run_elastix"]
    elastix_path = param_path["path_elastix"]
    parameter_files = param_path[parameter_files_key]
    euler_logfile = param_path["name_head_rotate_logfile"]
    
    cpu_per_task = param[cpu_per_task_key]
    mem = param[memory_key]
    duration = param[duration_key]
    fixed_channel = param[fixed_channel_key]
    moving_channel = param[moving_channel_key]
    job_name = param[job_name_key]
    email = param["email"]
    use_sbatch = param["use_sbatch"]
    server = param["server"]
    user = param["user"]
    array_size = param["array_size"]


    # erase previous scripts and replace them with new ones
    if clear_cmd_dir
        println("Resetting $(cmd_dir_local)...")
        rm(cmd_dir_local, recursive=true, force=true)
    end
    create_dir(cmd_dir_local)
    create_dir(cmd_dir_array_local)
    duration_str = Dates.format(duration, "HH:MM:SS")

    # Euler registration requires knowing worm head location
    use_euler = (head_rotate_path !== nothing)
    if use_euler
        if head_dir === nothing
            raise(error("Head path cannot be empty if head rotation is being used"))
        end
        println("Getting head position...")
        head_pos = read_head_pos(head_dir)
        head_pos_moving = read_head_pos(head_dir_moving)
    end

    println("Writing elastix script files...")
    count = 1
    edges_in_arr = []
    for i in 1:length(edges)
        edge = edges[i]
        dir=string(edge[1])*"to"*string(edge[2])
        push!(edges_in_arr, joinpath(cmd_dir_remote, dir*".sh"))
        script_str=""
        fixed_final=lpad(edge[2],4,"0")
        moving_final=lpad(edge[1],4,"0")
        # set sbatch parameters in script
        if use_sbatch
            # if using array, only set them in array
            if cmd_dir_array_local === nothing
                script_str *= replace("#!/bin/bash
                #SBATCH --job-name=$(job_name)
                #SBATCH --output=$(log_dir)/elx_$(dir).txt
                #SBATCH --nodes=1
                #SBATCH --ntasks=1
                #SBATCH --cpus-per-task=$(cpu_per_task)
                #SBATCH --time=$(duration_str)
                #SBATCH --mem=$(mem)G\n", "    " => "")
                if email !== nothing
                    script_str *= "#SBATCH --mail-user=$(email)
                    #SBATCH --mail-type=END\n"
                end
            elseif length(edges_in_arr) == array_size || i == length(edges)
                # modify in case we finished all the scripts
                modified_array_size = length(edges_in_arr)
                array_str = ""
                array_str *= replace("#!/bin/bash
                #SBATCH --job-name=$(job_name)
                #SBATCH --output=$(log_dir)/$(job_name)_%J.out
                #SBATCH --error=$(log_dir)/$(job_name)_%J.err
                #SBATCH --nodes=1
                #SBATCH --cpus-per-task=$(cpu_per_task)
                #SBATCH --time=$(duration_str)
                #SBATCH --mem=$(mem)G
                #SBATCH --array=1-$(modified_array_size)\n", "    " => "")
                if email !== nothing
                    array_str *= "#SBATCH --mail-user=$(email)
                    #SBATCH --mail-type=END\n"
                end
                script_list_file = joinpath(cmd_dir_remote, "$(job_name)_$(count).txt")
                array_str *= "$(run_elx_command) $(script_list_file) \$SLURM_ARRAY_TASK_ID\n"
                write_txt(joinpath(cmd_dir_local, "$(job_name)_$(count).txt"), reduce((x,y)->x*"\n"*y, edges_in_arr))
                write_txt(joinpath(cmd_dir_array_local, "$(job_name)_$(count).sh"), array_str)
                count += 1
                edges_in_arr = []
            end
        end


        # make directory
        reg = joinpath(reg_dir_remote, dir)
        script_str *= "[ ! -d $(reg) ] && mkdir $(reg)\n"

        # Euler registration
        if use_euler
            script_str *= "python $(head_rotate_path)"*
                " "*joinpath(MHD_dir_remote, get_basename(edge[2], fixed_channel)*".mhd")*
                " "*joinpath(MHD_dir_remote_moving, get_basename_moving(edge[1], moving_channel)*".mhd")*
                " "*joinpath(reg_dir_remote, dir, "$(dir)_euler.txt")*
                " $(head_pos[edge[2]][1]),$(head_pos[edge[2]][2])"*
                " $(head_pos_moving[edge[1]][1]),$(head_pos_moving[edge[1]][2]) > $(joinpath(reg_dir_remote, dir, euler_logfile))\n"
        end
        
        # elastix image and output parameters
        script_str *= elastix_path*
            " -f "*joinpath(MHD_dir_remote, get_basename(edge[2], fixed_channel)*".mhd")*
            " -m "*joinpath(MHD_dir_remote_moving, get_basename_moving(edge[1], moving_channel)*".mhd")*
            " -out "*joinpath(reg_dir_remote, dir)
        # mask parameters
        if mask_dir_local !== nothing
            script_str *= " -fMask "*joinpath(mask_dir_remote, get_basename(edge[2], fixed_channel)*".mhd")*
            " -mMask "*joinpath(mask_dir_remote_moving, get_basename_moving(edge[1], moving_channel)*".mhd")
        end
        # initial condition parameters
        if use_euler
            script_str *= " -t0 "*joinpath(reg_dir_remote, dir, "$(dir)_euler.txt")
        end
        # add parameter files
        for pfile in parameter_files
            script_str *= " -p $(pfile)"
        end
        # write elastix script
        script_str = mapfoldl(x->lstrip(x) * "\n", *, split(script_str, "\n"))
        filename = joinpath(cmd_dir_local, "$(dir).sh")
        open(filename, "w") do f
            write(f, script_str)
        end
    end

    println("Syncing data to server...")
    # make necessary directories on server
    run(`ssh $(user)@$(server) "mkdir -p $(data_dir_remote)"`)
    run(`ssh $(user)@$(server) "mkdir -p $(data_dir_remote_moving)"`)
    run(`ssh $(user)@$(server) "mkdir -p $(log_dir)"`)
    reg = reg_dir_remote
    run(`ssh $(user)@$(server) "mkdir -p $(reg)"`)
    # sync all data to the server
    if clear_cmd_dir
        run(Cmd(["rsync", "-r", "--delete", cmd_dir_local*"/", "$(user)@$(server):"*cmd_dir_remote]))
        if cmd_dir_array_local !== nothing
            run(Cmd(["rsync", "-r", "--delete", cmd_dir_array_local*"/", "$(user)@$(server):"*cmd_dir_array_remote]))
        end
    else
        run(Cmd(["rsync", "-r", cmd_dir_local*"/", "$(user)@$(server):"*cmd_dir_remote]))
        if cmd_dir_array_local !== nothing
            run(Cmd(["rsync", "-r", cmd_dir_array_local*"/", "$(user)@$(server):"*cmd_dir_array_remote]))
        end
    end
    run(Cmd(["rsync", "-r", MHD_dir_local*"/", "$(user)@$(server):"*MHD_dir_remote]))
    if data_dir_local_moving != data_dir_local
        run(Cmd(["rsync", "-r", "--delete", MHD_dir_local_moving*"/", "$(user)@$(server):"*MHD_dir_remote_moving]))
    end
    if mask_dir_local !== nothing
        run(Cmd(["rsync", "-r", "--delete", mask_dir_local*"/", "$(user)@$(server):"*mask_dir_remote]))
        if data_dir_local_moving != data_dir_local
            run(Cmd(["rsync", "-r", "--delete", mask_dir_local_moving*"/", "$(user)@$(server):"*mask_dir_remote_moving]))
        end
    end
end



"""
Runs elastix on OpenMind. Requires `julia` to be installed under the relevant username and activated in the default ssh shell.
Note that you cannot have multiple instances of this command running simultaneously with the same `temp_dir`.

# Arguments
- `cmd_dir_remote::String`: Directory on OpenMind where the elastix sbatch scripts will be stored.
- `tmp_dir::String`: Temporary directory to store scripts and lists
- `user::String`: Username on OpenMind

# Optional keyword arguments
- `server::String`: OpenMind server to ssh into. Default openmind7.mit.edu
- `partition::String`: Partition to run scripts on in sbatch. Default use-everything
"""
function run_elastix_openmind(param_path::Dict, param::Dict)
    temp_dir = param_path["path_om_tmp"]
    temp_file = joinpath(temp_dir, "elx_commands.txt")
    all_temp_files = joinpath(temp_dir, "*")
    cmd_path = param_path["path_dir_cmd"]
    if param_path["path_dir_cmd_array"] !== nothing
        cmd_path = param_path["path_dir_cmd_array"]
    end
    cmd_dir_remote = replace(cmd_path, param_path["path_root_process"] => param_path["path_om_data"])
    all_script_files = joinpath(cmd_dir_remote, "*")
    user = param["user"]
    server = param["server"]
    partition = param["partition"]
    run(`ssh $(user)@$(server) "mkdir -p $(temp_dir)"`)
    run(`ssh $(user)@$(server) "rm -f $(all_temp_files)"`)
    run(`ssh $(user)@$(server) "ls -d $(all_script_files) > $(temp_file)"`)
    run(`ssh $(user)@$(server) "julia -e \"using SLURMManager; submit_scripts(\\\"$(temp_file)\\\", partition=\\\"$(partition)\\\")\""`)
end


"""
Gets the number of running and pending `squeue` commands from the given user.

# Arguments
- `user::String`: Username on OpenMind

# Optional keyword arguments
- `server::String`: OpenMind server to ssh into. Default openmind7.mit.edu
"""
function get_squeue_status(param::Dict)
    user = param["user"]
    server = param["server"]
    running = run_parse_int(pipeline(`ssh $(user)@$(server) "julia -e \"using SLURMManager; println(squeue_n_running(\\\"$(user)\\\"))\""`))
    pending = run_parse_int(pipeline(`ssh $(user)@$(server) "julia -e \"using SLURMManager; println(squeue_n_pending(\\\"$(user)\\\"))\""`))
    return running + pending
end

"""
This function stalls until all the user's jobs on OpenMind are completed.

# Arguments
- `user::String`: Username on OpenMind

# Optional keyword arguments
- `delay::Integer`: Time to wait between server queries, in seconds. Default 300.
- `server::String`: OpenMind server to ssh into. Default openmind7.mit.edu
"""
function wait_for_elastix(param::Dict)
    while get_squeue_status(param) > 0
        sleep(param["elx_wait_delay"])
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
function sync_registered_data(param_path::Dict, param::Dict; reg_dir_key=path_dir_reg)
    reg_dir_local = param_path[reg_dir_key]
    create_dir(reg_dir_local)
    user = param["user"]
    server = param["server"]
    reg_dir_remote = replace(reg_dir_local, param_path["path_root_process"] => param_path["path_om_data"])
    run(Cmd(["rsync", "-r", "$(user)@$(server):"*reg_dir_remote*"/", reg_dir_local]))
end

"""
Updates parameter paths in transform parameter files, to allow `transformix` to be run on them.
Returns a dictionary of errors per problem and resolution.

# Arguments
- `problems`: Registration problems to update
- `rootpath::String`: Working directory of the data on your machine.
- `data_dir_remote::String`: Working directory of data on the remote server.
- `resolutions`: Array of number of elastix resolutions that have transform parameter files for each parameter file.

# Optional keyword arguments
- `reg_dir::String`: Directory of registered data. Default `Registered`.
"""
function fix_param_paths(problems, param_path::Dict, param::Dict; reg_dir_key::String="path_dir_reg")
    errors = Dict()
    reg_dir_local = param_path[reg_dir_key]
    resolutions = param["reg_n_resolution"]
    rootpath = param_path["path_root_process"]
    @showprogress for problem in problems
        errors[problem] = Dict()
        dir = joinpath(reg_dir_local, "$(problem[1])to$(problem[2])")
        for i=1:length(resolutions)
            filename = joinpath(dir, "TransformParameters.$(i-1).txt")
            try
            modify_parameter_file(filename, filename, Dict(param_path["path_om_data"] => rootpath); is_universal=true)
            catch e
                errors[problem][i] = e
            end
            for j=1:resolutions[i]
                filename = joinpath(dir, "TransformParameters.$(i-1).R$(j-1).txt")
                try
                    modify_parameter_file(filename, filename, Dict(param_path["path_om_data"] => rootpath); is_universal=true)
                catch e
                    errors[problem][(i,j)] = e
                end
            end
        end
    end
    return errors
end
