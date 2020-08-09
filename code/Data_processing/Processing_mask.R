##########################################
####  Create processing mask
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################



# Load packages -----------------------------------------------------------


pacman::p_load(Rahat, tidyverse, sf, raster)

esa_mask <- "Projects/Agriculture_modeling/Data/processing_mask.tif" %>% 
  milkunize2("archive") %>%
  raster()

"Projects/Land_use/Data/Predictors/Resampled/" %>% 
  milkunize2("archive") %>% 
  list.files(full.names = TRUE) %>% 
  map(raster)



variable_names <- "Projects/Land_use/Data/Predictors/Resampled" %>% 
  milkunize2("archive") %>% 
  list.files(pattern = "Soil_", full.names = TRUE) %>% 
  head(1)


esa_mask_filename <- "Projects/Agriculture_modeling/Data/processing_mask.tif" %>% 
  milkunize2("archive")

esa_mask <- raster(esa_mask_filename)


####
# Create polygon with the processing extent -----------------------------------------------------------

proc_extent_filename <- "Projects/Agriculture_modeling/Data/processing_mask.gpkg" %>% 
  milkunize2("archive")

if (file.exists(proc_extent_filename))
{
  df <- matrix(c(-180, 180, 84, -57), nrow = 1, ncol = 4)
  colnames(df) <- c("north_lat", "south_lat", "east_lng", "west_lng")
  str(df)
  
  lst <- lapply(1:nrow(df), function(x){
    ## create a matrix of coordinates that also 'close' the polygon
    res <- matrix(c(df[x, 'north_lat'], df[x, 'west_lng'],
                    df[x, 'north_lat'], df[x, 'east_lng'],
                    df[x, 'south_lat'], df[x, 'east_lng'],
                    df[x, 'south_lat'], df[x, 'west_lng'],
                    df[x, 'north_lat'], df[x, 'west_lng'])  ## need to close the polygon
                  , ncol =2, byrow = T
    )
    ## create polygon objects
    st_polygon(list(res))
    
  })
  
  ## st_sfc : creates simple features collection
  ## st_sf : creates simple feature object
  sfdf <- st_sf(geohash = "test", st_sfc(lst), crs = 4326)
  
  st_write(sfdf, proc_extent_filename)  
}
#### 
# Crop processing mask to processing extent

out_mask_filename <- "Projects/Agriculture_modeling/Data/processing_mask_cropped.tif" %>% 
  milkunize2("archive")

if (!file.exists(out_mask_filename))
{
  gdalR::GDAL_crop(esa_mask_filename, out_mask_filename, shapefile_path = proc_extent_filename, large_tif = TRUE)  
}

out_mask_filename_rcl <- "Projects/Agriculture_modeling/Data/processing_mask_cropped_binary.tif" %>% 
  milkunize2("archive")

# Reclassify ESA landcover to 1

mystring <- glue::glue("gdal_calc.py -A {out_mask_filename} --outfile={out_mask_filename_rcl} --calc=\"A*(A==0)+1\" --NoDataValue=0")
system(mystring)

#################################

