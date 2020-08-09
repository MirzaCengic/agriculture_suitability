#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=6:00:00
#SBATCH --output "/Logs/road_dist.log"
#SBATCH --mem=32G



##########################################
####  Road distance variables
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


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

# Project back from polar to wgs standard
road_dist_rprj_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_road_distance_wgs_1km_reprojected.tif" %>% 
  milkunize2("archive") 

road_polar_name <- milkunize2("Road_dist_polar_1km.tif", "archive")



wgs_prj <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

# Convert to polar equidistant projection
if (!file.exists(road_dist_rprj_filename))
{
  print("Reprojecting urban to polar projection")
  tic("Reprojecting urban to polar projection")
  GDAL_reproject(road_polar_name, road_dist_rprj_filename, crs_target = wgs_prj, method = "mode", return_raster = F)
  toc()
}


###  Process road distance
# Set out name
rdist_ltr_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_road_distance_logtr.tif" %>% 
  milkunize2("archive")


if (!file.exists(rdist_ltr_filename))
{
  
  logtr_command <- glue("gdal_calc.py -A {road_dist_rprj_filename} --calc \"log10(A+1)\" --type Float32 --outfile {rdist_ltr_filename}")
  # gdal_calc.py -A test.tif --calc "log(A)" --type Float32 --outfile log_test.tif
  system(logtr_command)
  
}





#### Load normalized file from .py and harmonize (resample) to final 

rdist_norm_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/ESA_road_distance_norm_1km.tif" %>% 
  milkunize2("archive")

rdist_fnl_filename <- "Projects/Agriculture_modeling/Data/Predictors_final/ESA_road_distance_norm_final.tif" %>% 
  milkunize2("archive")

"Projects/Agriculture_modeling/R/gdal_resample.R" %>% 
  milkunize2() %>% 
  source()

if (!file.exists(rdist_fnl_filename))
{
  
  tic("Harmonizing crops")
  GDAL_resample2(infile = rdist_norm_filename, outfile = rdist_fnl_filename, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  toc()
}
