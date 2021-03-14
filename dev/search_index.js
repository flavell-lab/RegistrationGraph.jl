var documenterSearchIndex = {"docs":
[{"location":"postprocessing/#Post-Processing-API","page":"Post-Processing API","title":"Post-Processing API","text":"","category":"section"},{"location":"postprocessing/","page":"Post-Processing API","title":"Post-Processing API","text":"average_am_registrations\nmake_quality_dict\ncalculate_ncc\nmetric_tfm","category":"page"},{"location":"postprocessing/#RegistrationGraph.average_am_registrations","page":"Post-Processing API","title":"RegistrationGraph.average_am_registrations","text":"Averages together registrations. All regstration parameters (including image size) must be the same except for the TransformParameters.\n\nArguments\n\nt_range: Time points to register\nparam_path::Dict: Dictionary containing paths to parameter files\nreg_dir_key::String (optional, default path_dir_reg_activity_marker): Key in param_path containing registration directory\ntransform_key::String (optional, default name_transform_activity_marker): Key in param_path contaning transform file names\ntransform_avg_key::String (optional, default name_transform_activity_marker_avg): Key in param_path contaning averaged transform file names (to be created)\nkey_param_key::String (optional, default key_transform_parameters): Key in param_path containing the TransformParameters key.\navg_fn::Function (optional, default median): Function used to average together registrations. Default median.\n\n\n\n\n\n","category":"function"},{"location":"postprocessing/#RegistrationGraph.make_quality_dict","page":"Post-Processing API","title":"RegistrationGraph.make_quality_dict","text":"Computes the quality of registration using NCC, nearest-neighbors distance between centroids, and manual annotation. Returns a dictionary of registration quality values for each resolution, another dictionary of the best resolution for each problem, and a dictionary of registration resolutions that failed. Outputs a text file containing registration quality values at the best resolution. It is assumed that smaller values are better for the metrics.\n\nArguments\n\nproblems: list of registration problems to compute the quality of\nevaluation_functions::Dict: dictionary of metric names to functions that evaluate elastix quality on a pair of images.   The evaluation functions will be given rootpath, fixed, moving, resolution, and possibly mask_dir as input, so be sure their   other parameters have been initialized correctly. It is assumed that the functions output floating-point metric values.\nselection_metric::String: which metric should be used to select the best registration out of the set of possible registrations\nresolutions: an array of resolution values to be using. Each value is represented as a tuple (i,j), where i is the number of parameter file   to use and j is the resolution for registrations using that parameter file. Both are 0-indexed.\n\nOptional Keyword Arguments\n\nmask_dir::String: directory to a mask file. Statistics will not be computed on regions outside the mask.   If left blank, no mask will be used or passed to the evaluation functions.\n\n\n\n\n\nComputes the quality of registration using NCC, nearest-neighbors distance between centroids, and manual annotation. Returns a dictionary of registration quality values for each resolution, another dictionary of the best resolution for each problem, and a dictionary of registration resolutions that failed. Outputs a text file containing registration quality values at the best resolution. It is assumed that smaller values are better for the metrics.\n\nArguments\n\nparam_path::Dict: Dictionary containing path_dir_mask entry to the path of masks (or nothing if no masks are used)\nparam::Dict: Dictionary containing the following keys:\nquality_metric::String: which metric should be used to select the best registration out of the set of possible registrations\ngood_registration_resolutions: an array of resolution values to be using. Each value is represented as a tuple (i,j), where i is the number of parameter file   to use and j is the resolution for registrations using that parameter file. Both are 0-indexed.\nproblems: list of registration problems to compute the quality of\nevaluation_functions::Dict: dictionary of metric names to functions that evaluate elastix quality on a pair of images.   The evaluation functions will be given rootpath, fixed, moving, resolution, and possibly mask_dir as input, so be sure their   other parameters have been initialized correctly. It is assumed that the functions output floating-point metric values.\n\n\n\n\n\n","category":"function"},{"location":"postprocessing/#RegistrationGraph.calculate_ncc","page":"Post-Processing API","title":"RegistrationGraph.calculate_ncc","text":"Computes the NCC of two image arrays moving and fixed corresponding to a registration.\n\n\n\n\n\n","category":"function"},{"location":"postprocessing/#RegistrationGraph.metric_tfm","page":"Post-Processing API","title":"RegistrationGraph.metric_tfm","text":"Applies a function to ncc to make it a cost that increases to infinity if ncc decreases below threshold (default 0.9)\n\n\n\n\n\n","category":"function"},{"location":"graphs/#Graph-Construction-API","page":"Graph Construction API","title":"Graph Construction API","text":"","category":"section"},{"location":"graphs/#Commonly-Used-Functions","page":"Graph Construction API","title":"Commonly Used Functions","text":"","category":"section"},{"location":"graphs/","page":"Graph Construction API","title":"Graph Construction API","text":"generate_elastix_difficulty\nload_graph\nmake_voting_subgraph\noutput_graph","category":"page"},{"location":"graphs/#RegistrationGraph.generate_elastix_difficulty","page":"Graph Construction API","title":"RegistrationGraph.generate_elastix_difficulty","text":"Generates an elastix difficulty file based on the given heuristic.\n\nArguments\n\npath_elastix_difficulty::String: output file\nt_range: list or range of time points to compute the difficulty\nheuristic: a heuristic function that evaluates \"distance\" betwen two frames.   The function will be given t1, and t2 as input, so be sure its   other parameters have been initialized correctly. It is assumed that the function outputs floating-point values.\n\n\n\n\n\nGenerates an elastix difficulty file based on the given heuristic.\n\nArguments\n\nparam_path::Dict: Dictionary of paths containing path_elastix_difficulty key to the path of the elastix difficulty output file\nt_range: list or range of time points to compute the difficulty\nheuristic: a heuristic function that evaluates \"distance\" betwen two frames.   The function will be given t1, and t2 as input, so be sure its   other parameters have been initialized correctly. It is assumed that the function outputs floating-point values.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.load_graph","page":"Graph Construction API","title":"RegistrationGraph.load_graph","text":"Loads an adjacency matrix from a file and stores it as a graph. You can specify a function to apply to each weight. This is often helpful in cases where the heuristic obeys the triangle inequality, to avoid the function from generating a star graph and mostly ignoring the heuristic. By default, the function is x->x^1.05, which allows the algorithm to split especially difficult registration problems into many steps. If this results in too many failed registrations, try increasnig the difficulty_importance parameter; conversely, if there is too much error accumulation over long chains of registrations, try decreasing it.\n\nArguments\n\nelx_difficulty::String: a path to a text file containing a list of frames and an adjacency matrix.\nfunc (optional): a function to apply to each element of the adjacency matrix\ndifficulty_importance (optional, default 0.05): if func is not provided, it will be set to x->x^(1+difficulty_importance)\n\nReturns a graph graph::SimpleWeightedGraph storing the adjacency matrix.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.make_voting_subgraph","page":"Graph Construction API","title":"RegistrationGraph.make_voting_subgraph","text":"Makes a subgraph of a graph, where each node is connected to their degree closest neighbors. Returns the subgraph, and an array of nodes that were disconnected from the rest of the nodes.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.output_graph","page":"Graph Construction API","title":"RegistrationGraph.output_graph","text":"Outputs subgraph::SimpleWeightedDiGraph to an output file outfile containing a list of edges in subgraph. Can set max_fixed_t::Int parameter if a dataset-alignment registration is being done.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#Other-Functions","page":"Graph Construction API","title":"Other Functions","text":"","category":"section"},{"location":"graphs/","page":"Graph Construction API","title":"Graph Construction API","text":"to_dict\nremove_frame\nupdate_graph\nremove_previous_registrations\noptimize_subgraph","category":"page"},{"location":"graphs/#RegistrationGraph.to_dict","page":"Graph Construction API","title":"RegistrationGraph.to_dict","text":"Converts a graph::SimpleWeightedGraph into an adjacency dictionary node => Dict({neighbor1 => weight1, neighbor2=> weight2, ...})\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.remove_frame","page":"Graph Construction API","title":"RegistrationGraph.remove_frame","text":"Given a graph graph::SimpleWeightedGraph and a problematic frame::Integer, deletes the frame from the graph without changing frame indices.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.update_graph","page":"Graph Construction API","title":"RegistrationGraph.update_graph","text":"Recomputes the difficulty graph based on registration quality data. Returns a new graph where difficulties of registration problems are scaled by the quality metric.\n\nArguments\n\nreg_quality_arr::Array{String,1} is an array of paths to files containing registration quality data\ngraph::SimpleWeightedGraph is the difficulty graph to be updated\nmetric::String is which quality metric to use to update the graph\n\nOptional keyword arguments\n\nmetric_tfm: Function to apply to each metric value. Default identity.\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.remove_previous_registrations","page":"Graph Construction API","title":"RegistrationGraph.remove_previous_registrations","text":"Removes previous registrations from the subgraph.\n\nArguments:\n\nprevious_problems: list of registration problems\nsubgraph::SimpleWeightedDiGraph: current subgraph\n\n\n\n\n\n","category":"function"},{"location":"graphs/#RegistrationGraph.optimize_subgraph","page":"Graph Construction API","title":"RegistrationGraph.optimize_subgraph","text":"Finds the minimum node of a graph, which has the smallest average shortest path length to each other node in that graph. Unconnected nodes are counted as having a path length equal to the highest edge weight.\n\nParameters\n\ngraph::SimpleWeightedGraph: a graph\n\nReturns:\n\nmin_node::Integer: the minimum node\nsubgraph::SimpleWeightedDiGraph: an unweighted graph whose edges consist of shortest paths from the minimum node of the original graph to other nodes.\nmaximum_problem_chain::Integer: the number of vertices in the longest chain of registration problems in the subgraph.\n\nThis graph is directed, and only has edges going away from the minimum node.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#Data-Visualization-API","page":"Data Visualization API","title":"Data Visualization API","text":"","category":"section"},{"location":"visualization/#Commonly-Used-Functions","page":"Data Visualization API","title":"Commonly Used Functions","text":"","category":"section"},{"location":"visualization/","page":"Data Visualization API","title":"Data Visualization API","text":"make_diff_pngs\nmake_diff_pngs_base\nmhd_to_png","category":"page"},{"location":"visualization/#RegistrationGraph.make_diff_pngs","page":"Data Visualization API","title":"RegistrationGraph.make_diff_pngs","text":"Makes PNG files to visualize how well the registration worked, by overlaying fixed and moving images. The fixed image will be red and the moving image will be green, so yellow indicates good registration.\n\nArguments\n\nparam_path::Dict: Dictionary containing paths to files\nparam::Dict: Dictionary containing parameter setting reg_n_resolution, an array of registration resolutions for each parameter file (eg for affine regstration with 3 resolutions   and bspline registration with 4 resolutions, this would be [3,4])\nget_basename::Function: Function mapping two timepoints to the base MHD filename corresponding to them.\nfixed::Integer: timestamp (frame number) of fixed image\nmoving::Integer: timestamp (frame number) of moving image\n\nOptional keyword arguments\n\nproj_dim::Integer: Dimension to project data. Default 3 (z-dimension)\nfixed_ch_key::Integer: Key in param to channel for the fixed image. Default ch_marker. (The moving image is the image automatically generated from the registration.)\nregdir_key::String: Key in param_path corresponding to the registration directory. Default path_dir_reg.\nmhd_key::String: Key in param_path corresponding to the MHD directory. Default path_dir_mhd_filt.\nresult::String: Name of resulting file. If left as default it the same as the corresponding MHD file.\ncontrast_f::Real: Contrast of fixed image portion of PNG. Default 1.\ncontrast_m::Real: Contrast of moving image portion of PNG. Default 1.\nswap_colors::Bool: If set to true, fixed image will be green and moving image will be red.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.make_diff_pngs_base","page":"Data Visualization API","title":"RegistrationGraph.make_diff_pngs_base","text":"Makes PNG files before registration, directly comparing two frames. The fixed image will be red and the moving image will be green, so yellow indicates good registration.\n\nArguments\n\nparam_path::Dict: Dictionary containing paths to files\nparam::Dict: Dictionary containing parameter settings\nget_basename::Function: Function mapping two timepoints to the base MHD filename corresponding to them.\nfixed::Integer: timestamp (frame number) of fixed image\nmoving::Integer: timestamp (frame number) of moving image\n\nOptional keyword arguments\n\nproj_dim::Integer: Dimension to project data. Default 3 (z-dimension)\nregdir_key::String: Key in param_path corresponding to the registration directory. Default path_dir_reg.\nmhd_key::String: Key in param_path corresponding to the MHD directory. Default path_dir_mhd_filt.\nmoving_ch_key::Integer: Key in param corresponding to channel for the moving image. Default ch_marker.\nfixed_ch_key::Integer: Key in param corresponding to channel for the fixed image. Default ch_marker.\ncontrast_f::Real: Contrast of fixed image portion of PNG. Default 1.\ncontrast_m::Real: Contrast of moving image portion of PNG. Default 1.\nswap_colors::Bool: If set to true, fixed image will be green and moving image will be red.\npng_name::String: Name of output file. Default noreg.png\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.mhd_to_png","page":"Data Visualization API","title":"RegistrationGraph.mhd_to_png","text":"Converts an mhd file at mhd_path::String into a PNG file, saved to path png_path::String, using maximum intensity projection. The optional argument proj_dim (default 3) can be changed to project in a different dimension.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#Other-Functions","page":"Data Visualization API","title":"Other Functions","text":"","category":"section"},{"location":"visualization/","page":"Data Visualization API","title":"Data Visualization API","text":"visualize_roi_predictions\nview_roi_regmap\ngen_regmap_rgb\nmake_rgb_arr\nplot_centroid_match","category":"page"},{"location":"visualization/#RegistrationGraph.visualize_roi_predictions","page":"Data Visualization API","title":"RegistrationGraph.visualize_roi_predictions","text":"Visualizes a comparison between an ROI image and a registration-mapped version.\n\nArguments\n\nimg_roi: ROI image in the fixed frame\nimg_roi_regmap: moving frame ROI image registration-mapped to the fixed frame\nimg: raw image in the fixed frame\nimg_regmap: raw image in the moving frame\n\nOptional keyword arguments\n\ncolor_brightness::Real: brightness of ROI colors. Default 0.3.\nplot_size: size of plot. Default (600, 600)\nroi_match: matches between ROIs in the two frames, as a dictionary whose keys are ROIs in the moving frame      and whose values are the corresponding ROIs in the fixed frame.\nunmatched_color: If set, all ROIs in the moving frame without a corresponding match in the fixed frame will be this color.\nmake_rgb: If set, will generate red vs green display of ROI locations.\nhighlight_rois: A list of ROIs in the fixed frame to be highlighted.\nhighlight_regmap_rois: A list of ROIs in the moving frame to be highlighted.\nhighlight_color: Highlight color, as an RGB. Default blue, aka RGB.(0,0,1)\ncontrast::Real: Contrast of raw images. Default 2.\nsemantic::Bool: If set to true, img_regmap should instead be a semantic segmentation of the fixed frame image. Default false.\nz_offset::Integer: z-offset of the moving image relative to the fixed image; the moving image will be shifted towards z=0 by this amount.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.view_roi_regmap","page":"Data Visualization API","title":"RegistrationGraph.view_roi_regmap","text":"Plots instance segmentation image and registration-mapped instance segmentation on the same plot, where each object is given a different color, the original image is shades of red, and the registration-mapped image is shades of green.\n\nArguments\n\nimg_roi: 3D instance segmentation image\nimg_roi_regmap: 3D instance segmentation image from another frame, mapped via registration.\n\nOptional keyword arguments\n\ncolor_brightness::Real: minimum RGB value (out of 1) that an object will be plotted with. Default 0.3\nplot_size: size of the plot. Default (600,600)\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.gen_regmap_rgb","page":"Data Visualization API","title":"RegistrationGraph.gen_regmap_rgb","text":"Generates a colormap that encodes the difference between the ROI image and the registration-mapped version using shades of red and green.\n\nArguments\n\nimg_roi: ROI image in the fixed frame\nimg_roi_regmap: moving frame ROI image registration-mapped to the fixed frame\n\nOptional keyword arguments\n\ncolor_brightness::Real: maximum brightness of ROIs. Default 1.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.make_rgb_arr","page":"Data Visualization API","title":"RegistrationGraph.make_rgb_arr","text":"Makes a PyPlot-compatible RGB array out of red, green, and blue channels.\n\n\n\n\n\n","category":"function"},{"location":"visualization/#RegistrationGraph.plot_centroid_match","page":"Data Visualization API","title":"RegistrationGraph.plot_centroid_match","text":"Plots fixed, and inferred moving, centroids over the fixed worm image. Additionally, draws lines between matched centroids.\n\nArguments\n\nfixed_image: fixed image of the worm (2D) matches: List of pairs of centroids (which are tuples of (x,y) coordinates) that match. centroids_actual: centroids determined directly from the fixed image centroids_inferred: centroids determined from the moving image, and then mapped onto the fixed image via registration.\n\n\n\n\n\n","category":"function"},{"location":"#Registration.jl-Documentation","page":"Registration.jl Documentation","title":"Registration.jl Documentation","text":"","category":"section"},{"location":"","page":"Registration.jl Documentation","title":"Registration.jl Documentation","text":"Pages = [\"graphs.md\", \"openmind.md\", \"postprocessing.md\", \"visualization.md\"]","category":"page"},{"location":"openmind/#OpenMind-Interaction-API","page":"OpenMind Interaction API","title":"OpenMind Interaction API","text":"","category":"section"},{"location":"openmind/","page":"OpenMind Interaction API","title":"OpenMind Interaction API","text":"write_sbatch_graph\nsync_registered_data\nfix_param_paths\nrun_elastix_openmind\nget_squeue_status\nwait_for_elastix","category":"page"},{"location":"openmind/#RegistrationGraph.write_sbatch_graph","page":"OpenMind Interaction API","title":"RegistrationGraph.write_sbatch_graph","text":"Syncs data from local computer to a remote server and creates command files for elastix on that server. WARNING: This program can permanently delete data if run with incorrect arguments.\n\nArguments\n\nedges: List of registration problems to perform\nparam_path_fixed::Dict: Dictionary containing paths for the fixed images including:\nget_basename: Function that maps channel and time point to MHD filename\npath_dir_cmd: Path to elastix command directory\npath_om_cmd: Path to elastix command directory on the server\npath_dir_cmd_array: Path to elastix array command directory\npath_om_cmd_array: Path to elastix array command directory on the server\npath_om_log: Path to log file on server\npath_run_elastix: Path to script that runs elastix given command on the server\npath_elastix: Path to elastix executable on the server\nname_head_rotate_logfile: Name of head rotate log files\nparam_path_moving::Dict: Dictionary containing paths for the moving images including the same keys as with the fixed dictionary.\nparam::Dict: Dictionary containing parameters including:\nemail: Email to inform user of task termination. If nothing, no emails will be sent\nuse_sbatch: Use sbatch, rather than directly running code on the server. This should always be set to true on OpenMind\nserver: Address of server to run code on\nuser: Username on server\narray_size: Size of sbatch array to use\ndata_dir_remote::String: Working directory of data on the remote server.\nimg_prefix::String: image prefix not including the timestamp. It is assumed that each frame's filename    will be, eg, img_prefix_t0123_ch2.mhd for frame 123 with channel=2.\nparameter_files::Array{String,1}: List of parameter files for elastix to use, in order of their application,    as stored on the remote server. These parameter files are NOT assumed to be in the working directory.\nchannel::Integer: The channel to use for registration.\nuser::String: Username on the server\n\nOptional keyword arguments\n\nclear_cmd_dir::Bool: Whether to clear the elastix command directory, useful if you are re-running registrations\ncpu_per_task_key::String: Key in param to CPU cores per elastix task. Default cpu_per_task\nmemory_key::String: Key in param to memory per elastix task. Default memory\nduration_key::String: Key in param to the duration of each elastix task. Default duration\njob_name_key::String: Key in param to the name of the elastix tasks. Default job_name\nfixed_channel_key::String: Key in param to the fixed channel. Default ch_marker\nmoving_channel_key::String: Key in param to the moving channel. Default ch_marker\nhead_dir_key::String: Key in param_path_* to the head position of the worm. Default path_head_pos\nom_data_key::String: Key in param_path_* to the path to sync the data on the server. Default path_om_data\nMHD_dir_key::String: Key in param_path_* to the path to the MHD files. Default path_dir_mhd_filt\nMHD_om_dir_key::String: Key in param_path_* to the path to the MHD files on the server. Default path_om_mhd_filt\nmask_dir_key::String: Key in param_path_* to the mask path. Default path_dir_mask\nmask_om_dir_key::String: Key in param_path_* to the mask path on the server. Default path_om_mask\nreg_dir_key::String: Key in param_path_* to the registration output directory. Default path_dir_reg\nreg_om_dir_key::String: Key in param_path_* to the registration output directory on the server. path_om_reg\npath_head_rotate_key::String: Key in param_path_fixed to the path on the server to the head rotation python file. Default path_head_rotate\nparameter_files_key::String: Key in param_path_fixed to the path on the server to the elastix parameter files. Default parameter_files\n\n\n\n\n\n","category":"function"},{"location":"openmind/#RegistrationGraph.sync_registered_data","page":"OpenMind Interaction API","title":"RegistrationGraph.sync_registered_data","text":"Syncs registration data from a remote compute server back to the local computer.\n\nArguments\n\nparam_path::Dict: Dictionary of paths\nparam::Dict: Dictionary of parameters including:\nuser: Username on OpenMind\nserver: Login node address on OpenMind\nreg_dir_key::String (optional, default path_dir_reg): Key in param_path to the path to the registration output directory\nreg_om_dir_key::String (optional, default path_om_reg): Key in param_path to the path to the registration output directory on the server\n\n\n\n\n\n","category":"function"},{"location":"openmind/#RegistrationGraph.fix_param_paths","page":"OpenMind Interaction API","title":"RegistrationGraph.fix_param_paths","text":"Updates parameter paths in transform parameter files, to allow transformix to be run on them. Returns a dictionary of errors per problem and resolution.\n\nArguments\n\nproblems: Registration problems to update\nparam_path::Dict: Dictionary of paths including:\npath_root_process: Path to data\npath_om_data: Path to data on server\nparam::Dict: Dictionary of parameters\nreg_dir_key::String (optional, default path_dir_reg): Key in param_path to the path to the registration output directory\nn_resolution_key::String (optional, default reg_n_resolution): Key in param to array of number of registrations with each parameter file\n\n\n\n\n\n","category":"function"},{"location":"openmind/#RegistrationGraph.run_elastix_openmind","page":"OpenMind Interaction API","title":"RegistrationGraph.run_elastix_openmind","text":"Runs elastix on OpenMind. Requires julia to be installed under the relevant username and activated in the default ssh shell. Note that you cannot have multiple instances of this command running simultaneously with the same temp_dir.\n\nArguments\n\nparam_path::Dict: Dictionary of parameter paths including:\npath_om_tmp: Path to temporary directory on OpenMind.\npath_om_cmd: Path to elastix command directory on OpenMind.\npath_om_cmd_array: Path to elastix array command directory on OpenMind.\nparam::Dict: Dictionary of parameter settings including:\nuser: OpenMind username\nserver: Login node address on OpenMind\npartition: Partition to run elastix using (eg use-everything)\n\n\n\n\n\n","category":"function"},{"location":"openmind/#RegistrationGraph.get_squeue_status","page":"OpenMind Interaction API","title":"RegistrationGraph.get_squeue_status","text":"Gets the number of running and pending squeue commands from the given user.\n\nArguments\n\nparam::Dict: Parameter dictionary including:\nuser: Username on OpenMind\nserver: Login node address on OpenMind\n\n\n\n\n\n","category":"function"},{"location":"openmind/#RegistrationGraph.wait_for_elastix","page":"OpenMind Interaction API","title":"RegistrationGraph.wait_for_elastix","text":"This function stalls until all the user's jobs on OpenMind are completed.\n\nArguments\n\nparam::Dict: Parameter dictionary including:\nuser: Username on OpenMind\nserver: Login node address on OpenMind\nelx_wait_delay: Time to wait between checking whether elastix is done, in seconds\n\n\n\n\n\n","category":"function"}]
}
