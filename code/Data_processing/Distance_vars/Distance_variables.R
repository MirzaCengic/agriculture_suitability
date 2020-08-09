#!#!/usr/bin/env Rscript

#!#SBATCH --partition=milkun
#!#SBATCH --mail-type=FAIL
#!#SBATCH --mail-user=mirzaceng@gmail.com
#!#SBATCH --time=14-00:00:00
#!#SBATCH --output "/Logs/Distance_vars_calc.log"
#!#SBATCH --mem=64G

##########################################
####  Distance variables
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, glue, tictoc, sf)

# infile - raster for which to calculate distances
# outfile - output filename
# to_tiff - convert .sdat file to .tiff; default is FALSE
SAGA_distance <- function(infile, outfile, to_tiff = TRUE)
{
  
  # if(pkgmaker::file_extension(outfile) == "tif")
  # {
  #   outfile <- gsub(".tif", ".sgrd", outfile)
  # }
  
  saga_call <- glue::glue("saga_cmd grid_tools 26 -FEATURES {infile} -DISTANCE {outfile}")
  #   system(saga_call)
  gdal_call <-   glue::glue("gdal_proximity.py {infile} {outfile}")
  system(gdal_call)  
  # if (isTRUE(to_tiff))
  # {
  #   system(paste0("gdal_translate -of GTiff", " ", gsub("sgrd", "sdat", pkgmaker::file_extension(outfile)), " ",  gsub("sgrd", "tif", pkgmaker::file_extension(outfile))))
  # }
}
# Get filenames -----------------------------------------------------------

esa_path <- "ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2002-v2.0.7.tif" %>% 
  milkunize2("data")

urban_outname <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_urban.tif" %>% 
  milkunize2("archive")

urban_distance <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_urban_distance.tif" %>% 
  milkunize2("archive")

roads_subset_filename <- "Projects/Agriculture_modeling/Data/GRIP_roads_subset.gpkg" %>% 
  milkunize2("archive")

roads_rasterized <- "Projects/Agriculture_modeling/Data/Predictors_temp/Roads_rasterized.tif" %>% 
  milkunize2("archive")

roads_distance <- "Projects/Agriculture_modeling/Data/Predictors_temp/Roads_distance.tif" %>% 
  milkunize2("archive")

# Process roads -----------------------------------------------------------

if (!file.exists(roads_subset_filename))
{
  print("Subsetting GRIP")
  grip_raw <- "Data_RAW/Shapefiles/GRIP/GRIP4_GlobalRoads.gdb" %>% 
    milkunize2("archive") %>% 
    st_read()
  
  grip_subset <- grip_raw %>% 
    filter(GP_RTP != 5)
  
  st_write(grip_subset, roads_subset_filename)
}

# Rasterize roads
if (!file.exists(roads_rasterized))
{
  print("Rasterizing")
  tic("Rasterizing roads")
  rasterize_call <- glue::glue("gdal_rasterize -tr 0.002777777777778 0.002777777777778 -te -180 -57 180 84 -l GRIP_roads_subset -burn 1 -a_nodata NA -co compress=LZW {roads_subset_filename} {roads_rasterized}")
  system(rasterize_call)
  toc()
}

# Get distance variables --------------------------------------------------
# Extract urban cells
if (!file.exists(urban_outname))
{
  print("Reclassifying")
  tic("Reclassifying urban")
  string_urban <- glue::glue("gdal_calc.py -A {esa_path} --outfile={urban_outname} --calc=\"A*(A==190)\" --NoDataValue=0")
  system(string_urban)
  toc()
}

# Calculate distance
if (!file.exists(urban_distance))
{
  print("Distcalc urban")
  tic("Calculating distance from urban")
  SAGA_distance(infile = urban_outname, outfile = urban_distance, to_tiff = TRUE)  
  toc()
}

if (!file.exists(roads_distance))
{
  print("Distcalc roads")
  tic("Calculating distance from roads")
  SAGA_distance(infile = roads_rasterized, outfile = roads_distance, to_tiff = TRUE)  
  toc()
}


####