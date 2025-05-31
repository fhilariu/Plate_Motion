# PlateMotionSimulator.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://fhilariu.github.io/PlateMotionSimulator.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://fhilariu.github.io/PlateMotionSimulator.jl/dev/)
[![Build Status](https://github.com/fhilariu/PlateMotionSimulator.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/fhilariu/PlateMotionSimulator.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/fhilariu/PlateMotionSimulator.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/fhilariu/PlateMotionSimulator.jl)


This package simulates the evolution of plate tectonics from today to 540 Ma and is based on the dataset of Scotese & Wright (2018). It uses GLMakie to create an interactive 3D-Plot of the globe, whose surface represents a colored height model showing the topography of each timestep. Various GUI-elements such as input via textboxes and confirmation via buttons support the ease of use. Special features include the adjustment of exaggeration, manual limits for the colorbar and a selection of different colormaps as well as the storage of mp4-recordings in a specific section on the globe over the hole time period. A mode for displaying the height difference of 5 Ma each is also included. Furthermore this package provides a 2D visualization of the datasets in form of heatmaps. 

This julia code is indepedent of the currently used dataset and can therfore be easily applied to other datasets.


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
"using Pkg"
```
3. Download the Pkg:
```
"Pkg.add(url="https://github.com/fhilariu/Plate_Motion")"
```
4. Load the Package:
```
using PlateMotionSimulator
```
5. Start the GUI:
```
main()
```
This step may take a while as the dataset will be downloaded from the EarthByte website.

## 2D-example




## 3D-Example
When everything is ready the GUI should look like that:

<img width="1440" alt="PlateMotionSimulator" src="https://github.com/user-attachments/assets/466b4b7c-491b-461e-b406-1fec2042e0c8" />

Now you're ready to go. 

******_Note if you want to save the .mp4 you must provide a file path_******
```
cd(Path/to/folder)
```

## Dependencies
We use [NCDatasets.jl[(https://github.com/JuliaGeo/NCDatasets.jl) to read NetCDF-files from scientific datasets, GLMakie.jl to create 2D heatmaps and interactive 3D-plots with GUIs, GeoMakie.jl to project a surface on the 3D globe, Statistics.jl to compute statistic parameters of the elevation data, GeometryBasics.jl to manage geometry objects in background, Downloads.jl to download datasets from scientific websites, and Printf.jl for string formatting.

By installing PlateMotionSimulator.jl, all of these dependencies should be installed automatically.






