#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=124:00:00
#SBATCH --output "/Logs/Rasterize_roads.log"
#SBATCH --mem=64G

##########################################
####  Rasterize road vectorfile
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, glue, tictoc, sf)


GDAL_reproject <- function(infile, outfile, crs_target, method, return_raster = FALSE)
{
  if (!method %in% c("near", "bilinear", "cubic", "cubicspline", "lanczos",
                     "average", "mode", "max", "min", "med", "q1", "q3")) {
    stop("Resampling method not available.")
  }
  
  if (inherits(infile, "Raster"))
  {
    infile <- infile@file@name
  }
  
  proj.cmd.warp <- paste0("gdalwarp -t_srs", " ", "'",
                          crs_target,"'" , " ","-r", " ", method, " ", "-of vrt")
  
  print(paste(proj.cmd.warp, infile, gsub(tools::file_ext(outfile), "vrt", outfile)))
  # Reproject to vrt in order to conserve space
  system(command = paste(proj.cmd.warp, infile, gsub(tools::file_ext(outfile), "vrt", outfile)))
  # Load and transform to tiff
  system(paste("gdal_translate -co compress=LZW -co BIGTIFF=YES", gsub(tools::file_ext(outfile), "vrt", outfile),
               outfile))
  # Remove vrt file
  unlink(gsub(tools::file_ext(outfile), "vrt", outfile))
  
  # Return raster
  if (isTRUE(return_raster)) {
    library(raster)
    out <-raster(outfile)
    return(out)
  }
}


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
roads_rasterized1km <- "Projects/Agriculture_modeling/Data/Predictors_temp/Roads_rasterized_1km.tif" %>% 
  milkunize2("archive")


roads_rasterized <- "Projects/Agriculture_modeling/Data/Predictors_temp/Roads_rasterized.tif" %>% 
  milkunize2("archive")

rr <- raster(roads_rasterized)
plot(rr)

if (!file.exists(roads_rasterized1km))
{
  print("Rasterizing")
  tic("Rasterizing roads")
  rasterize_call <- glue::glue("gdal_rasterize -tr 0.008333333 0.008333333 -te -180 -57 180 84 -l GRIP_roads_subset -burn 1 -a_nodata NA -co compress=LZW {roads_subset_filename} {roads_rasterized}")
  # rasterize_call <- glue::glue("gdal_rasterize -tr 0.2777777777778 0.2777777777778 -te -180 -57 180 84 -l GRIP_roads_subset -burn 1 -a_nodata NA -co compress=LZW {roads_subset_filename} {roads_rasterized}")
  system(rasterize_call)
  toc()
}


if (!file.exists(roads_rasterized))
{
  print("Rasterizing")
  tic("Rasterizing roads")
  rasterize_call <- glue::glue("gdal_rasterize -tr 0.002777777777778 0.002777777777778 -te -180 -57 180 84 -l GRIP_roads_subset -burn 1 -a_nodata NA -co compress=LZW {roads_subset_filename} {roads_rasterized}")
  # rasterize_call <- glue::glue("gdal_rasterize -tr 0.2777777777778 0.2777777777778 -te -180 -57 180 84 -l GRIP_roads_subset -burn 1 -a_nodata NA -co compress=LZW {roads_subset_filename} {roads_rasterized}")
  system(rasterize_call)
  toc()
}

# Urban areas layer with polar projection
roads_polar <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_roads_polar_prj3.tif" %>% 
  milkunize2("archive")

polar_prj <- "+proj=aeqd +lat_0=90 +lon_0=0"

# Convert to polar equidistant projection
if (!file.exists(roads_polar))
{
  print("Reprojecting roads to polar projection")
  tic("Reprojecting roads to polar projection")
  GDAL_reproject(roads_rasterized, roads_polar, crs_target = polar_prj, method = "mode", return_raster = FALSE)
  toc()
}