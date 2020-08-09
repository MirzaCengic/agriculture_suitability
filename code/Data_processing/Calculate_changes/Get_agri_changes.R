##########################################
####  Get changes between two timesteps
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# This script will take two land cover rasters, split them in many small parts (in parallel),
# and calculate the differences where land has been converted into agriculture

# It is called by separate scripts, which are names Run_*period*_*category*.R
# This is because 2 different parameters are needed - crop category, and period (fit/eval).

# Script setup ------------------------------------------------------------
pacman::p_load(raster, rgdal, Rahat, tictoc, sf, fs, LUpak, gdalR, glue, foreach)


# Load data ---------------------------------------------------------------


## Create folders
# This is the folder that will contain the output data

folder_basepath <- glue("Projects/Agriculture_modeling/Data/Changes_vector/{changes_type}/Presences") %>% 
  milkunize2("archive")
dir.create(folder_basepath, recursive = TRUE, showWarnings = FALSE)

# Load data ####
# Previous and future land cover

if (changes_type == "Fit")
{
  mybrick <- stack(milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2003-v2.0.7.tif", "data"), 
                   milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2013-v2.0.7.tif", "data"))	
} 
if (changes_type == "Eval")
{
  mybrick <- stack(milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992-v2.0.7.tif", "data"), 
                   milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2003-v2.0.7.tif", "data"))	
}

# Mask to which point data is rarified
bioclim_mask <- "Chelsa/CHELSA_bioclim/CHELSA_bio10_1.tif" %>% 
  milkunize2("data") %>% 
  raster()

##%######################################################%##
#                                                          #
####                     Main loop                      ####
#                                                          #
##%######################################################%##

#### Main ####

# Necessary steps
# - load two rasters
# - run get change
# - raster to point
# - rarify point

#### Set category stuff ####
# Set condition to merge rainfed changes
if (category == "10")
{
  crop_category <- 10:21
} else {
  crop_category <- as.numeric(category)
}

#### Set output names ####
# Change raster filepath

raster_out_filename <- glue("{folder_basepath}/Presence_{tolower(changes_type)}_{as.character(category)}.tif")
# Change shapefile (not rarified)
shape_out_filename <- glue("{folder_basepath}/Presence_{tolower(changes_type)}_{as.character(category)}_300m.gpkg")
# Change shapefile (rarified)
shape_out_rare_filename <- glue("{folder_basepath}/Presence_{tolower(changes_type)}_{as.character(category)}_1km.gpkg")

###########


#### Get change from two rasters ####
# Check if raster exists and substract two raster if not

source("get_change_raster_GDAL.R")

if (!file.exists(raster_out_filename))
{
  print("Getting change.")
  tic(glue("Getting change for {changes_type} {category}."))
  
  
  change_raster <- get_change_raster_GDAL(x = mybrick[[1]], y = mybrick[[2]],
                                          outpath = paste0("/scratch/R_temp_mosaic_", tolower(changes_type), category),
                                          outfile = raster_out_filename,
                                          category = crop_category, number_of_cores = n_cores)
  
  
  toc()
  
} else {
  # Load raster otherwise
  change_raster <- raster(raster_out_filename)
}
#### Get change shapefile ####
# Check if shapefile exists
if (!file.exists(shape_out_filename)) 
{
  # Raster to points
  print("Raster to points.")
  tic(paste0("Raster to points for ", category))
  change_points <- raster::rasterToPoints(change_raster, sp = TRUE, fun = function(x){x == 1})
  toc()
  
  change_points_sf <- st_as_sf(change_points)
  st_write(change_points_sf, shape_out_filename)
} else {
  change_points_sf <- st_read(shape_out_filename)
}

#### Rarify points ####
if (!file.exists(shape_out_rare_filename))
{
  cat(paste0("Rarifying category ", category), "\n")
  change_points_1km <- as(change_points_sf, "Spatial")
  toc("Rarifying...")
  my_crops_rarified <- rarify_points(change_points_1km, bioclim_mask)
  st_write(my_crops_rarified, shape_out_rare_filename)
  toc()
} else {
  my_crops_rarified <- st_read(shape_out_rare_filename)	   
}

