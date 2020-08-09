#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=12:00:00
#SBATCH --output "/Logs/DEM_resampling.log"
#SBATCH --mem=48G

##########################################
####  Process DEM
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Reference for creating the northness variable
# https://www.nature.com/articles/sdata201840.pdf
# http://spatial-ecology.net/dokuwiki/doku.php?id=wiki:grass:grasstopovar


# Script setup ------------------------------------------------------------
pacman::p_load(Rahat, tidyverse, raster, tictoc, glue)

source("gdal_resample.R")

# Function to calculate slope
# degrees unit argument is for input rasters with degrees as horizontal unit (i.e. lat/long).
# If input is projected, set degrees_unit to FALSE
GDAL_slope <- function(infile, outfile, degrees_unit = TRUE, return_raster = FALSE)
{
  
  if(isTRUE(degrees_unit))
  {  
    GDAL_call <- glue::glue("gdaldem slope -compute_edges -s 111120 {infile} {outfile} -co BIGTIFF=YES -co compress=LZW")
    
  } else {
    GDAL_call <- glue::glue("gdaldem slope -compute_edges {infile} {outfile} -co BIGTIFF=YES -co compress=LZW")
    
  }
  
  system(GDAL_call)
  
  if( isTRUE(return_raster)){
    r_slope <- raster::raster(outfile)
    return(r_slope)
  }
}

# GDAL_aspect
# zero_flat argument returns 0 for flat areas instead of -9999. Default is TRUE.
GDAL_aspect <- function(infile, outfile, zero_flat = TRUE, return_raster = FALSE)
{
  
  if(isTRUE(zero_flat))
  {  
    GDAL_call <- glue::glue("gdaldem aspect -compute_edges -zero_for_flat {infile} {outfile} -co BIGTIFF=YES -co compress=LZW")
  } else {
    GDAL_call <- glue::glue("gdaldem aspect -compute_edges {infile} {outfile} -co BIGTIFF=YES -co compress=LZW")
    
  }
  
  system(GDAL_call)
  
  if( isTRUE(return_raster)){
    r_slope <- raster::raster(outfile)
    return(r_slope)
  }
}
# Set filenames ---------------------------------------------------------------
dem_path_raw <- "Merit_DEM/Merit_DEM_mosaic.tif" %>% 
  milkunize2("data")


dem_resampled <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/DEM_resampled.tif" %>% 
  milkunize2("archive")

slope_filename <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/DEM_slope.tif" %>% 
  milkunize2("archive")

aspect_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/DEM_aspect.tif" %>% 
  milkunize2("archive")

aspect_cosine_filename <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/tmp3/aspect_cosine_mosaic.tif")

northness_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/DEM_northness.tif" %>% 
  milkunize2("archive")
# Resampling --------------------------------------------------------------


# Resample layer

if (!file.exists(dem_resampled))
{
  
  tic("Resample DEM")
  GDAL_resample2(infile = dem_path_raw, outfile = dem_resampled, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "average", large_tif = TRUE)
  toc()
  
}


#### Calculate DEM variables
# Calculate slope ---------------------------------------------------------
if (!file.exists(slope_filename))
{
  
  tic("Calculate slope")
  GDAL_slope(infile = dem_resampled, outfile = slope_filename, degrees_unit = TRUE, return_raster = FALSE)  
  toc()
  
}

# Logtransform slope
slope_ltr_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/DEM_slope_logtr.tif" %>% 
  milkunize2("archive")


if (!file.exists(slope_ltr_filename))
{
  
  logtr_command <- glue("gdal_calc.py -A {slope_filename} --calc \"log10(A+1)\" --type Float32 --outfile {slope_ltr_filename}")
  # gdal_calc.py -A test.tif --calc "log(A)" --type Float32 --outfile log_test.tif
  system(logtr_command)
  
}

# Normalize slope


# Harmonize slope variable
slope_harmonized_filename <- "Projects/Agriculture_modeling/Data/Predictors_final/Slope_fnl.tif" %>% 
  milkunize2("archive")

if (!file.exists(slope_harmonized_filename))
{
  
  tic("Harmonizing slope")
  GDAL_resample2(infile = slope_ltr_filename, outfile = slope_harmonized_filename, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  toc()
}

# Calculate aspect
if (!file.exists(aspect_filename))
{
  tic("Calculate aspect")
  GDAL_aspect(infile = dem_resampled, outfile = aspect_filename, return_raster = FALSE)  
  toc()
}

####
# Calculate cosine 


aspect_cosine_filename <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/tmp3/aspect_cosine_mosaic3.tif")

if (!file.exists(aspect_cosine_filename))
{
  tic("Calculate aspect cosine")
  cosine_call <- glue::glue("gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --overwrite --co=BIGTIFF=YES --type=Float32 -A {aspect_filename} --calc=\"(cos(A.astype(float)* 3.14159 / 180 ))\" --outfile {aspect_cosine_filename}")
  system(cosine_call)
  toc()
}

# Calculate northness 
r <- raster(northness_filename)
plot(r)


####
if (!file.exists(northness_filename))
{
  tic("Calculate northness")
  northness_call <- glue::glue("gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --overwrite --co=BIGTIFF=YES --type=Float32 -A {slope_filename} -B {aspect_cosine_filename} --calc=\"((sin(A.astype(float) * 3.141592 / 180 ))*B)\" --outfile {northness_filename}")
  system(northness_call)
  toc()
}

# Harmonize northness variable
northness_harmonized_filename <- "Projects/Agriculture_modeling/Data/Predictors_final/DEM_northness_fnl.tif" %>% 
  milkunize2("archive")


if (!file.exists(northness_harmonized_filename))
{
  
  tic("Harmonizing northness")
  GDAL_resample2(infile = northness_filename, outfile = northness_harmonized_filename, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  toc()
}
