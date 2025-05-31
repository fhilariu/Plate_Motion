module PlateMotionSimulator

using GLMakie
using NCDatasets
using GeometryBasics 
using GeoMakie
using Downloads
using Printf
using Statistics

export main


# backend for GLMakie
GLMakie.activate!()
Makie.inline!(true)

# function to generate temporal directory for datasets
function download_and_extract(destdir="data")
    url = "https://zenodo.org/record/5460860/files/Scotese_Wright_2018_Maps_1-88_6minX6min_PaleoDEMS_nc.zip?download=1"
    zip_path = joinpath(destdir, "Scotese_Wright_2018_Maps_1-88_6minX6min_PaleoDEMS_nc.zip")
    
    if !isdir(destdir)
        mkpath(destdir)
    end

    # download zip file
    if !isfile(zip_path)
        println("Downloading dataset...")
        Downloads.download(url, zip_path)
    else
        println("Dataset ZIP already downloaded.")
    end
    
    # unpack zip files
    extracted_folder = joinpath(destdir, "Scotese_Wright_2018_Maps_1-88_6minX6min_PaleoDEMS_nc")
    if !isdir(extracted_folder)
        println("Extracting ZIP with PowerShell...")
        run(`powershell -command "Expand-Archive -LiteralPath '$zip_path' -DestinationPath '$destdir' -Force"`)
    else
        println("Dataset already extracted.")
    end

    return extracted_folder
end

# function to extract years and index
function get_years_and_index()
    # directory of nc files
    directory     = joinpath("data", "Scotese_Wright_2018_Maps_1-88_6minX6min_PaleoDEMS_nc")
    nc_files      = filter(f -> endswith(f, ".nc"), readdir(directory))
    sorted_files  = sort(nc_files, by=f -> parse(Int, match(r"(\d+)Ma", f).captures[1]))
    nc_file_paths = joinpath.(directory, sorted_files)

    # generate years from timesteps
    year_to_index = Dict{Int, Int}()
    index_to_year = Dict{Int, Int}() 

    for (i, file) in enumerate(sorted_files)
        match_result = match(r"(\d+)Ma", file)
        if match_result !== nothing
            year = parse(Int, match_result.captures[1]) 
            year_to_index[year] = i  
            index_to_year[i] = year  
        end
    end

    available_years = sort(collect(keys(year_to_index)), rev=true)

    return available_years, year_to_index, index_to_year, nc_file_paths
end

# function to read data from nc files
function read_data()
    # call function to get years and index
    _, _, _, nc_file_paths = get_years_and_index()

    # generate longitude and latitude from first nc file
    data = NCDataset(nc_file_paths[1])
    lon  = data["longitude"]
    lat  = data["latitude"]

    all_longitude = zeros(length(lon), 1)
    all_latitude  = zeros(length(lat), 1)
    all_elevation = zeros(length(lon), length(lat), length(nc_file_paths))
    
    # convertion to arrays
    all_longitude[:, 1] .= Array(lon)
    all_latitude[:, 1]  .= Array(lat)
    
    close(data)

    # loop over all maps to save elevation data
    for i in 1:length(nc_file_paths)
        data = NCDataset(nc_file_paths[i])
        elevation = data["z"]
        all_elevation[:, :, i] .= Array(elevation)

        close(data)
    end

    return all_longitude, all_latitude, all_elevation
end

# function to call and save pictures of heatmaps
function picture_heatmap()
    # call functions to read data & get years and index
    all_longitude, all_latitude, all_elevation = read_data()
    available_years, year_to_index, index_to_year, _ = get_years_and_index()

    # initialize heatmap
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Longitude", ylabel="Latitude", xticks=-180:90:180, yticks=-90:45:90)
    hm = heatmap!(ax, all_longitude[:, 1], all_latitude[:, 1], all_elevation[:, :, 1], 
                  colormap=:oleron, colorrange=(-maximum(abs.(all_elevation[:, :, 1])), maximum(abs.(all_elevation[:, :, 1]))))
    Colorbar(fig[1, 2], hm, label="Elevation [m]", flip_vertical_label=true, labelsize=15, ticklabelsize=15)
    display(fig)

    # update heatmap for all timesteps
    for i in 1:size(all_elevation, 3)
        hm[3] = all_elevation[:, :, i]  
        current_year = index_to_year[i]  
        ax.title = "Heatmaps based on Scotese & Wright (2018) - Year $current_year [Ma]"
        display(fig)
        sleep(0.5)
        save("Heatmaps based on Scotese & Wright (2018) - Year $current_year [Ma].png", fig)
    end
end

# function to save heatmaps as mp4
function record_heatmap()
    # call functions to read data & get years and index
    all_longitude, all_latitude, all_elevation = read_data()
    _, _, index_to_year, _ = get_years_and_index()

    # initialize heatmap
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Longitude", ylabel="Latitude", xticks=-180:90:180, yticks=-90:45:90)
    hm = heatmap!(ax, all_longitude[:, 1], all_latitude[:, 1], all_elevation[:, :, 1], 
                  colormap=:oleron, colorrange=(-maximum(abs.(all_elevation[:, :, 1])), maximum(abs.(all_elevation[:, :, 1]))))
    Colorbar(fig[1, 2], hm, label="Elevation [m]", flip_vertical_label=true, labelsize=15, ticklabelsize=15)

    # record heatmap for all timesteps
    record(fig, "Heatmaps based on Scotese & Wright (2018).mp4", 1:size(all_elevation, 3); framerate=1) do i
        hm[3] = all_elevation[:, :, i] 
        current_year = index_to_year[i] 
        ax.title = "Heatmaps based on Scotese & Wright (2018) - Year $current_year [Ma]"
    end
end

# function to initialize globe attributes
function initialize_globe_attributes()
    all_longitude, all_latitude, all_elevation = read_data()

    lon_data = all_longitude[:, 1]
    lat_data = all_latitude[:, 1]
    el_data  = all_elevation[:, :, 1]

    return lon_data, lat_data, el_data, all_elevation
end

# function to correct latitude values
function correct_latitudes(lat_data::Vector{Float64}; tolerance=1e-5)
    corrected_lat_data = copy(lat_data)  
    
    for i in 1:length(lat_data)
        lat = lat_data[i]
        
        if abs(lat - 90.0) < tolerance
            corrected_lat_data[i] = 90.0
        elseif abs(lat + 90.0) < tolerance
            corrected_lat_data[i] = -90.0
        else
            corrected_lat_data[i] = clamp(lat, -90.0, 90.0)
        end
    end
    
    return corrected_lat_data
end

# function to correct longitude values
function correct_longitudes(lon_data::Vector{Float64}; tolerance=1e-5)
    corrected_lon_data = copy(lon_data)  
    
    for i in 1:length(lon_data)  
        lon = lon_data[i]
        
        if abs(lon - 180.0) < tolerance
            corrected_lon_data[i] = 180.0
        elseif abs(lon + 180.0) < tolerance
            corrected_lon_data[i] = -180.0
        else
            corrected_lon_data[i] = clamp(lon, -180.0, 180.0)
        end
    end
    
    return corrected_lon_data
end

# function to adjust globe data
function adjust_globe_data(lon_data, lat_data, el_data)
    if lon_data[1] != lon_data[end]
        append!(lon_data, lon_data[1])  
        append!(lat_data, lat_data[1])  
        el_data = vcat(el_data, el_data[1, :]')  
        el_data = hcat(el_data, el_data[:, 1]) 
    end

    return lon_data, lat_data, el_data
end

# function to initialize globe parameters
function initialize_globe_parameters(lat_data, lon_data)
    R_erde = 6371e3
    MT_EVEREST_HEIGHT = 8848.0
    θ = LinRange(0, π, length(lat_data))
    φ = LinRange(0, 2π, length(lon_data))

    return R_erde, MT_EVEREST_HEIGHT, θ, φ
end

# function to compute initial globe coordinates
function compute_globe(el_data, R_erde, θ, φ, α)
    x = [(R_erde + α * el_data'[i, j]) * cos(φ[j]) * sin(θ[i]) for i in eachindex(θ), j in eachindex(φ)]
    y = [(R_erde + α * el_data'[i, j]) * sin(φ[j]) * sin(θ[i]) for i in eachindex(θ), j in eachindex(φ)]
    z = [(R_erde + α * el_data'[i, j]) * cos(θ[i]) for i in eachindex(θ), j in eachindex(φ)]

    return x, y, z
end

# function to update globe coordinates
function compute_globe!(x, y, z, el_data, R_erde, θ, φ, α)
    x .= [(R_erde + α * el_data'[i, j]) * cos(φ[j]) * sin(θ[i]) for i in eachindex(θ), j in eachindex(φ)]
    y .= [(R_erde + α * el_data'[i, j]) * sin(φ[j]) * sin(θ[i]) for i in eachindex(θ), j in eachindex(φ)]
    z .= [(R_erde + α * el_data'[i, j]) * cos(θ[i]) for i in eachindex(θ), j in eachindex(φ)]
end

# function to compute equator
function compute_equator()
    # call functions
    lon_data, lat_data, el_data, all_elevation = initialize_globe_attributes()
    lon_data, lat_data, el_data = adjust_globe_data(lon_data, lat_data, el_data)
    R_erde, _, _, φ = initialize_globe_parameters(lat_data, lon_data)

    # set height above surface
    max_elevation = maximum(all_elevation)
    safety_margin = 20.0 * max_elevation  
    height_above_surface = max_elevation + safety_margin

    # compute coordinates of equator
    eq_x = (R_erde .+ height_above_surface) .* cos.(φ)
    eq_y = (R_erde .+ height_above_surface) .* sin.(φ)
    eq_z = (R_erde .+ height_above_surface) .* zeros(length(φ)) 

    return eq_x, eq_y, eq_z
end

# function to check if a value is an outlier
function is_outlier(value, threshold)
    
    return abs(value) > threshold
end

# function to perform neighbor search and replace outliers
function filter_outliers(el_data, threshold)
    filtered_data = copy(el_data)
    global_median = median(el_data)
    rows, cols    = size(el_data)

    for i in 1:rows
        for j in 1:cols
            if is_outlier(el_data[i, j], threshold)
                
                i_min = max(1, i-1)
                i_max = min(rows, i+1)
                j_min = max(1, j-1)
                j_max = min(cols, j+1)

                neighbors = el_data[i_min:i_max, j_min:j_max]
                neighbors = neighbors[.!is_outlier.(neighbors, threshold)]
                
                if !isempty(neighbors)
                    filtered_data[i, j] = mean(neighbors)
                else
                    filtered_data[i, j] = global_median
                end
            end
        end
    end
    return filtered_data
end

# function to reset camera view
function reset_camera(ax)
    center!(ax.scene)
    println("Camera reset to initial view.")
end

# main function to run simulation
function main()
    # call functions to read data and initialize globe attributes
    data_dir = download_and_extract("data")
    lon_data, lat_data, el_data, all_elevation = initialize_globe_attributes()
    lon_data, lat_data, el_data = adjust_globe_data(lon_data, lat_data, el_data)
    R_erde, MT_EVEREST_HEIGHT, θ, φ = initialize_globe_parameters(lat_data, lon_data)
    eq_x, eq_y, eq_z = compute_equator()

    # calculate initial parameters of globe
    el_data_first    = all_elevation[:, :, 1]
    el_data_first    = vcat(el_data_first, el_data_first[1, :]') 
    el_data_first    = hcat(el_data_first, el_data_first[:, 1]) 
    el_data_filtered = zeros(size(el_data_first, 1), size(el_data_first, 2))
    el_data_filtered_first = filter_outliers(el_data_first, MT_EVEREST_HEIGHT)
    α = Observable(50.0)
    x, y, z = compute_globe(el_data_filtered_first, R_erde, θ, φ, α[])

    # calculate elevation changes
    available_years, year_to_index, index_to_year, _ = get_years_and_index()
    dt_values = diff(collect(values(index_to_year)))  
    change_elevation = diff(all_elevation, dims=3) ./ reshape(dt_values, 1, 1, :)

    # initialize plot
    fig = Figure(size=(800, 600), backgroundcolor=:grey80)
    ax = LScene(fig[1, 3], show_axis=false, tellheight=true, tellwidth=false, width=1250, height=620)
    label = Label(fig[0, 3], text="Plate Motion Simulator based on Scotese & Wright (2018) - Year 0 [Ma]", color=:black, fontsize=20, tellwidth=false)

    # initialize observables 
    idx = Observable(1)
    use_diff = Observable(false)
    is_playing = Observable(false) 
    use_mp4 = Observable(false)
    use_rev = Observable(false) 
    manual_colorrange = Observable((-maximum(abs.(all_elevation[:, :, 1])), maximum(abs.(all_elevation[:, :, 1]))))  

    # initialize gui elements
    Box_0 = Box(fig[3, 4:7], cornerradius=0, strokecolor=:black, color=:transparent)
    tb_year          = Textbox(fig[3, 6], width=100, placeholder="Enter Age [Ma]", validator=Int, bordercolor=RGBf(0.0, 0.0, 0.0), boxcolor_focused=RGBf(1.0, 0.0, 0.0), 
                               displayed_string = @lift(string(index_to_year[$idx])))
    input_label        = Label(fig[3, 4], text="Enter a Number to change Year [Ma] -->", fontsize=15, width=100, halign=:left)
    update_button     = Button(fig[3, 7], label="Update", buttoncolor_hover=RGBf(0.0, 0.0, 1.0), buttoncolor_active=RGBf(0.0, 1.0, 0.0), width=100)
    
    Box_1 = Box(fig[6, 5:7], cornerradius=0, strokecolor=:black, color=:transparent)
    tb_min             = Textbox(fig[6, 5], width=100, placeholder="Min Value", validator=Float64, bordercolor=RGBf(0.0, 0.0, 0.0), boxcolor_focused=RGBf(1.0, 0.0, 0.0))
    tb_max             = Textbox(fig[6, 6], width=100, placeholder="Max Value", validator=Float64, bordercolor=RGBf(0.0, 0.0, 0.0), boxcolor_focused=RGBf(1.0, 0.0, 0.0))
    apply_limits_button = Button(fig[6, 7], label="Apply Colorbar", buttoncolor_hover=RGBf(0.0, 0.0, 1.0), buttoncolor_active=RGBf(0.0, 1.0, 0.0), width=100)
   
    Box_2 = Box(fig[4, 4:7], cornerradius=0, strokecolor=:black, color=:transparent)
    reset_zoom_button   = Button(fig[4, 7], label="Reset Zoom", buttoncolor_hover=RGBf(0.0, 0.0, 1.0), buttoncolor_active=RGBf(0.0, 1.0, 0.0), width=100)
    toggle_label         = Label(fig[4, 4], text="Toggle on for Elevation Changes [m/Ma] -->", fontsize=15, color=:black, width=150)
    toggle_button       = Toggle(fig[4, 6], active=false)

    Box_3 = Box(fig[5, 2:7], cornerradius=0, strokecolor=:black, color=:transparent)
    play_button     = Button(fig[5, 3], label="Play", buttoncolor_hover=RGBf(0.0, 0.0, 1.0), buttoncolor_active=RGBf(0.0, 1.0, 0.0), width=100, halign=:right)
    play_toggle     = Toggle(fig[5, 4], active=false, halign=:left)
    play_label       = Label(fig[5, 2], text="Press Button to start Simulation and toggle on to save as mp4 -->", fontsize=15, color=:black, width=200, halign=:left, 
                             tellwidth=false)
    play_rev_toggle = Toggle(fig[5, 7], active=false, halign=:right)
    play_label       = Label(fig[5, 6], text="Toggle on to play Reverse -->", fontsize=15, color=:black, width=200, halign=:center, 
                            tellwidth=false)

    Box_4 = Box(fig[6, 2:4], cornerradius=0, strokecolor=:black, color=:transparent)
    slider      = Slider(fig[6, 3], range=1:length(available_years), startvalue=1, snap=false, update_while_dragging=true, width=450, halign=:right)
    slider_label = Label(fig[6, 2], text="Slide Year [Ma]", fontsize=15, width=150, tellwidth=false, halign=:left)

    Box_5 = Box(fig[4, 2:3], cornerradius=0, strokecolor=:black, color=:transparent)
    exag_button = Button(fig[4, 3], label="Apply", buttoncolor_hover=RGBf(0.0, 0.0, 1.0), buttoncolor_active=RGBf(0.0, 1.0, 0.0), width=100, halign=:right)
    tb_exag    = Textbox(fig[4, 3], width=100, placeholder="50", validator=Float64, bordercolor=RGBf(0.0, 0.0, 0.0), boxcolor_focused=RGBf(1.0, 0.0, 0.0), halign=:center)
    exag_label = Label(fig[4, 2], text="Enter a Number to change Exaggeration -->", fontsize=15, halign=:left, color=:black, width=150, tellwidth=false)
        
    Box_6 = Box(fig[3, 2:3], cornerradius=0, strokecolor=:black, color=:transparent)
    menu_cb               = Menu(fig[3, 3], options = ["oleron", "turbo", "roma"], default = "oleron", width=100)    
    menu_label           = Label(fig[3, 2], text="Change Colormaps -->", fontsize=15, color=:black, halign=:left, width=100)     

    colorbar = Colorbar(fig[1, 7], colormap=:oleron, tellwidth=false, tellheight=true, colorrange = (-maximum(abs.(all_elevation[:, :, 1])), maximum(abs.(all_elevation[:, :, 1]))), 
                        label="Elevation [m]", flip_vertical_label = true, labelsize=15, ticklabelsize=15)

    globe = GeoMakie.surface!(ax, x, y, z, colormap=:oleron, color=el_data_filtered_first', shading=FastShading, backlight=1.5f0, 
            colorrange=(-maximum(abs.(el_data_filtered_first)), maximum(abs.(el_data_filtered_first))))

    zoom!(ax.scene, cameracontrols(ax.scene), 0.65)
    lines!(ax.scene, eq_x, eq_y, eq_z, color=:red, linewidth=2, linestyle=:solid)

    # synchronize slider with idx
    connect!(idx, slider.value) 

    # synchronize textbox input with slider
    on(update_button.clicks) do _
        input = coalesce(tb_year.stored_string[], "")
        
        if !isempty(input)
            new_idx = tryparse(Int, input)
            println("Parsed year: ", new_idx)
            if new_idx !== nothing && haskey(year_to_index, new_idx)
                set_close_to!(slider, year_to_index[new_idx])  
                idx[] = year_to_index[new_idx]
            elseif new_idx !== nothing 
                rounded_year = round(new_idx / 5) * 5
                if haskey(year_to_index, rounded_year)
                    set_close_to!(slider, year_to_index[rounded_year])  
                    idx[] = year_to_index[rounded_year]  
                    println("Rounded year to nearest 5 Ma step: ", rounded_year)        
                end
            end
        else
            println("Please enter a year in Ma.")
        end
    end

    # exag_button
    on(exag_button.clicks) do _
        input = coalesce(tb_exag.stored_string[], "")
        
        if !isempty(input)
            new_exag = tryparse(Float64, input)
            println("Parsed Exaggeration: ", new_exag)
            if new_exag !== nothing
                α[] = new_exag
                compute_globe!(x, y, z, el_data_filtered, R_erde, θ, φ, α[])
                globe.color = el_data_filtered'
                globe.x[] = x
                globe.y[] = y
                globe.z[] = z
            end
        else
            println("Please enter a valid exaggeration value.")
        end
    end

    # update idx when slider value changes
    on(slider.value) do _
        if toggle_button.active[]
            println("Update with elevation change mode active.")
        else
            println("Update with elevation change mode inactive.")
        end
    end

    # button to reset zoom
    on(reset_zoom_button.clicks) do _   
        reset_camera(ax)
    end

    # menu for colormap selection
    on(menu_cb.selection) do colormap
        globe.colormap  = Symbol(colormap)  
        colorbar.colormap = Symbol(colormap)
    end

    # toggle for elevation changes
    on(toggle_button.active) do state
        println("Elevation Toggle State changed: ", state ? "Active" : "Inactive")
        use_diff[] = state 
    end

    # toggle for play button
    on(play_toggle.active) do state
        println("Play Toggle State changed: ", state ? "Active" : "Inactive")
        use_mp4[] = state
    end

    # reverse toggle for play button
    on(play_rev_toggle.active) do state
        println("Reverse Toggle State changed: ", state ? "Active" : "Inactive")
        use_rev[] = state
    end

    # button to apply new colorbar limits
    on(apply_limits_button.clicks) do _
        min_input = tryparse(Float64, coalesce(tb_min.stored_string[], ""))
        max_input = tryparse(Float64, coalesce(tb_max.stored_string[], ""))
        
        if min_input !== nothing && max_input !== nothing && min_input < max_input
            colorbar.colorrange = (min_input, max_input)
            globe.colorrange = (min_input, max_input)  
            manual_colorrange[] = (min_input, max_input) 
            println("Updated colorbar and globe colormap limits: Min = $min_input, Max = $max_input")
        else
            println("Invalid input for colorbar limits. Ensure Min < Max and both are valid numbers.")
        end
    end

    # update globe data when idx changes
    on(idx) do i
        selected_year = get(index_to_year, i, nothing)    
        next_year = get(index_to_year, i + 1, nothing)

        if selected_year !== nothing

            if use_diff[] 
                if next_year !== nothing
                    dt = next_year - selected_year 
                else                    
                    println("Error: No next year found for year $selected_year Ma. Maximum year = 535 Ma")
                end
                el_data = change_elevation[:, :, i]
                if size(el_data, 1) != size(el_data_first, 1) || size(el_data, 2) != size(el_data_first, 2)
                    el_data = vcat(el_data, el_data[1, :]') 
                    el_data = hcat(el_data, el_data[:, 1])  
                end
                el_data_filtered .= filter_outliers(el_data, MT_EVEREST_HEIGHT)
                label.text = "Elevation Rate: $selected_year Ma → $next_year Ma [m/Ma]"
            else
                el_data = all_elevation[:, :, i]
                if size(el_data, 1) != size(el_data_first, 1) || size(el_data, 2) != size(el_data_first, 2)
                    el_data = vcat(el_data, el_data[1, :]')  
                    el_data = hcat(el_data, el_data[:, 1])  
                end
                el_data_filtered .= filter_outliers(el_data, MT_EVEREST_HEIGHT)
                label.text = "Plate Motion Simulator based on Scotese & Wright (2018) - Year $selected_year [Ma]"
            end

            # update parameters
            if manual_colorrange[] !== nothing
                colorbar.colorrange = manual_colorrange[]  
                globe.colorrange = manual_colorrange[]  
            else
                colorbar.colorrange = (-maximum(abs.(el_data_filtered)), maximum(abs.(el_data_filtered)))
                globe.colorrange = (-maximum(abs.(el_data_filtered)), maximum(abs.(el_data_filtered)))
            end
            globe.color = el_data_filtered'
            compute_globe!(x, y, z, el_data_filtered, R_erde, θ, φ, α[])
            globe.x[] = x
            globe.y[] = y
            globe.z[] = z
        else
            println("Error: No matching year found for index $i")
        end
    end

    # function to record mp4
    function record_playback(fig, idx, available_years, frames_per_timestep=30)
        println("Starting to record mp4")
        is_playing[] = true 

        # reverse playback
        if use_rev[]  
            record(fig, "playback_reverse.mp4", framerate=30) do io
                while is_playing[] && idx[] > 1
                    idx[] -= 1
                    
                    for _ in 1:frames_per_timestep
                        recordframe!(io)
                    end
                end
                is_playing[] = false
                println("Reverse MP4 recording finished and saved")
            end
        else  
            # forward playback
            record(fig, "playback.mp4", framerate=30) do io
                while is_playing[] && idx[] < length(available_years)
                    idx[] += 1

                    for _ in 1:frames_per_timestep
                        recordframe!(io)
                    end
                end
                is_playing[] = false
                println("MP4 recording finished and saved")
            end
        end
    end

    # playback button
    on(play_button.clicks) do _
        if is_playing[]  
            is_playing[] = false
            println("Playback stopped.")
        elseif use_mp4[]
            is_playing[] = true
            record_playback(fig, idx, available_years) 
        elseif use_rev[]
            is_playing[] = true
            println("Reverse playback started.")
            @async begin
                while is_playing[] && idx[] > 1  
                    idx[] -= 1
                    sleep(0.5) 
                end
                is_playing[] = false  
                println("Reverse playback finished.")
            end
        else
            is_playing[] = true
            println("Playback started.")
            @async begin
                while is_playing[] && idx[] < length(available_years)  
                    idx[] += 1 
                    sleep(0.5) 
                end
                is_playing[] = false  
                println("Playback finished.")
            end
        end
    end

    display(GLMakie.Screen(), fig)
end

# call main function
main()

end
