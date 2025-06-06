# PlateMotionSimulator.jl
This package simulates the evolution of plate tectonics from today to 540 Ma and is based on the dataset of Scotese & Wright (2018). It uses GLMakie to create an interactive 3D-Plot of the globe, whose surface represents a colored height model showing the topography of each timestep. Various GUI-elements such as input via textboxes and confirmation via buttons support the ease of use. Special features include the adjustment of exaggeration, manual limits for the colorbar and a selection of different colormaps as well as the storage of mp4-recordings in a specific section on the globe over the hole time period. A mode for displaying the height difference of 5 Ma each is also included. Furthermore this package provides a 2D visualization of the datasets in form of heatmaps. 

This julia code is indepedent of the currently used dataset and can therfore be easily applied to other datasets by changing the url, zip_path and directory.


## Contents
- **[PlateMotionSimulator.jl](#platemotionsimulator)**
  - [Contents](#contents)
  - [Installation](#installation)
  - [2D-Example](#2D-Example)
  - [3D-Example](#3D-Example)
  - [Dependencies](#dependencies)

## Installation
1. Start Julia

2. To download the Package you need the Package "Pkg". 
```
using Pkg
```
3. Download the Pkg:
```
Pkg.add(url="https://github.com/fhilariu/Plate_Motion")
```
4. Load the Package:
```
using PlateMotionSimulator
```

## 2D-Example
### Single pictures
To generate 2D-heatmaps from the Dataset use the function: 
```
picture_heatmap()
```
This will create an heatmap for every single timestep. 
![Heatmaps based on Scotese   Wright (2018) - Year 0  Ma](https://github.com/user-attachments/assets/35dc2939-0755-45d1-9b80-b97c85f7a8c5)

### 2D video 
To get a 2D animation of the plate tectonics use the function:
```
record_heatmap()
```
This will generate a .mp4 of all timesteps
![Heatmps_short](https://github.com/user-attachments/assets/7f84ee62-63e4-4f7e-b911-e413b1eeb20b)

> [!IMPORTANT]
>***_note that both functions need a storage location_***

## 3D-Example
Start the GUI:
```
main()
```
This step may take a while as the dataset will be downloaded from the EarthByte website.
When everything is ready the GUI should look like that:

<img width="1440" alt="PlateMotionSimulator" src="https://github.com/user-attachments/assets/466b4b7c-491b-461e-b406-1fec2042e0c8" />

Now you're ready to go. 
> [!IMPORTANT]
>***_Note that there has to be a storage location to save the .mp4_***
```
cd(Path/to/folder)
```

## Dependencies
We use [NCDatasets.jl](https://github.com/JuliaGeo/NCDatasets.jl) to read NetCDF-files from scientific datasets, [GLMakie.jl](https://github.com/JuliaPlots/GLMakie.jl) to create 2D heatmaps and interactive 3D-plots with GUIs, [GeoMakie.jl](https://github.com/MakieOrg/GeoMakie.jl) to project a surface on the 3D globe, [Statistics.jl](https://github.com/JuliaStats/Statistics.jl) to compute statistic parameters of the elevation data, [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl) to manage geometry objects in background, [Downloads.jl](https://github.com/JuliaLang/Downloads.jl) to download datasets from scientific websites, and [Printf.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/Printf) for string formatting.

By installing `PlateMotionSimulator.jl`, all of these dependencies should be installed automatically.






