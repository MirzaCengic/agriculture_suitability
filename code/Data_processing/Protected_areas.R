##########################################
####  Create predictor - protected areas
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Steps:
# 1 - Filter protected areas polygons to keep only what we need.
# 2 - Rasterize on a global level and save

# Load packages -----------------------------------------------------------

pacman::p_load(Rahat, raster, sf, tidyverse, fasterize, tictoc, gdalR)


# Load data ---------------------------------------------------------------

protected_areas_raw <- "Data_RAW/Shapefiles/WDPA/WDPA_Jul2019-shapefile-polygons.shp" %>%
  milkunize2("archive") %>%
  st_read()


PAs_cleaned <- protected_areas_raw %>%
  filter(MARINE == 0)  %>%
  filter(STATUS != "Proposed")


# Load ESA land cover mask. This will be used as a raster mask to rasteriye the polygon data.
esa_mask <- "Projects/Agriculture_modeling/Data/processing_mask.tif" %>% 
  milkunize2("archive") %>%
  raster()
rasterOptions(maxmemory = ncell(esa_mask) - 1)

# Rasterize data so background is 0, and protected is 1

pa_filename <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/Protected_areas.tif" %>% 
  milkunize2("archive")

if (!file.exists(pa_filename))
{
  
  tic("Rasterizing")
  pa_protected <- fasterize(PAs_cleaned, esa_mask, fun = "first", background = 0)
  toc()
  
  
  
  writeRaster(pa_protected, pa_filename, options = "COMPRESS=LZW")  
}

##### Harmonize
"Projects/Agriculture_modeling/R/gdal_resample.R" %>% 
  milkunize2() %>% 
  source()

# Load data ---------------------------------------------------------------

pa_harmonized_filename <- "Projects/Agriculture_modeling/Data/Predictors_final/Protected_areas_fnl.tif" %>% 
  milkunize2("archive")

if (!file.exists(pa_harmonized_filename))
{
  
  tic("Harmonizing PAs")
  GDAL_resample2(infile = pa_filename, outfile = pa_harmonized_filename, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "near", large_tif = TRUE)
  toc()
  
}
