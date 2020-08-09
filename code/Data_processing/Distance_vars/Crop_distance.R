##########################################
####  Calculate crop distance
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, glue, tictoc)

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
  gdal_call <-   glue("gdal_proximity.py {infile} {outfile}")
  system(gdal_call) 
  
  # if (isTRUE(to_tiff))
  # {
  #   system(paste0("gdal_translate -of GTiff", " ", gsub("sgrd", "sdat", pkgmaker::file_extension(outfile)), " ",  gsub("sgrd", "tif", pkgmaker::file_extension(outfile))))
  # }
}


# Define filenames ---------------------------------------------------------------

# Input
esa_path <- "ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2002-v2.0.7.tif" %>% 
  milkunize2("data")

# Reclassified
outname_10 <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_10.tif" %>% 
  milkunize2("archive")
outname_30 <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_30.tif" %>% 
  milkunize2("archive")
outname_40 <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_40.tif" %>% 
  milkunize2("archive")

# Distance names
outname_10_distance <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_10_distance.tif" %>% 
  milkunize2("archive")
outname_30_distance <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_30_distance.tif" %>% 
  milkunize2("archive")
outname_40_distance <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_40_distance.tif" %>% 
  milkunize2("archive")


# Reclassify land cover rasters -------------------------------------------

string_esa10 <- glue::glue("gdal_calc.py -A {esa_path} --outfile={outname_10} --calc=\"A*(A==10)+A*(A==11)+A*(A==12)+A*(A==20)\" --NoDataValue=0")
string_esa30 <- glue::glue("gdal_calc.py -A {esa_path} --outfile={outname_30} --calc=\"A*(A==30)\" --NoDataValue=0")
string_esa40 <- glue::glue("gdal_calc.py -A {esa_path} --outfile={outname_40} --calc=\"A*(A==40)\" --NoDataValue=0")


if (!file.exists(outname_10))
{
  tic("Reclassifying 10")
  system(string_esa10)
  toc()
  
}
#
if (!file.exists(outname_30))
{
tic("Reclassifying 30")
system(string_esa30)
toc()
}
#
if (!file.exists(outname_40))
{
tic("Reclassifying 40")
system(string_esa40)
toc()
}


# Reproject to equal area -------------------------------------------------


GDAL_reproject <- function(input, outfile, crs_target, method, return_raster = FALSE)
{
  if (!method %in% c("near", "bilinear", "cubic", "cubicspline", "lanczos",
                     "average", "mode", "max", "min", "med", "q1", "q3")) {
    stop("Resampling method not available.")
  }
  
  proj.cmd.warp <- paste0("gdalwarp -t_srs", " ", "'",
                          crs_target,"'" , " ","-r", " ", method, " ", "-of vrt")
  
  print(paste(proj.cmd.warp, input, gsub(pkgmaker::file_extension(outfile), "vrt", outfile)))
  # Reproject to vrt in order to conserve space
  system(command = paste(proj.cmd.warp, input, gsub(pkgmaker::file_extension(outfile), "vrt", outfile)))
  # Load and transform to tiff
  system(paste("gdal_translate -co compress=LZW", gsub(pkgmaker::file_extension(outfile), "vrt", outfile),
               outfile))
  # Remove vrt file
  unlink(gsub(pkgmaker::file_extension(outfile), "vrt", outfile))
  
  # Return raster
  if (isTRUE(return_raster)) {
    library(raster)
    out <-raster(outfile)
    return(out)
  }
}


outname_10_ea <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/ESA_crop_10_eqa2.tif" %>% 
  milkunize2("archive")

proj_ed <- "+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
proj <- "+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

# plot(rr)
if (!file.exists(outname_10_ea))
{
  tic("Reprojecting 10")
  GDAL_reproject(
    outname_10,
                 # esa_path,
                 outname_10_ea, crs_target = proj_ed, method = "bilinear")
  toc()
  
}


outname_10_distance2 <- str_replace(outname_10_distance, "e.tif", "e2.tif")
if (!file.exists(outname_10_distance2))
{
  tic("Calculating distance 10")
  SAGA_distance(outname_10_ea, outname_10_distance2)
  toc()
  
}


# Calculate distance ------------------------------------------------------

if (!file.exists(outname_10_distance))
{
  tic("Calculating distance 10")
  SAGA_distance(outname_10, outname_10_distance)
  toc()
  
}
#
if (!file.exists(outname_30_distance))
{
  tic("Calculating distance 30")
  SAGA_distance(outname_30, outname_30_distance)
  toc()
}
#
if (!file.exists(outname_40_distance))
{
  tic("Calculating distance 40")
  SAGA_distance(outname_40, outname_40_distance)
  toc()
}
# ####
