##########################################
####  Split predictors
##########################################
#### | Project name: Agriculture modeling 
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Split up predictors, then follow up with prediction_tiles.R

# Load packages -----------------------------------------------------------
pacman::p_load(Rahat, tidyverse, raster, tictoc)

# Load data ---------------------------------------------------------------

# Set here the folder in which the raster predictors are 
my_layers <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
  milkunize2("archive") %>% 
  list.files(full.names = TRUE, pattern = ".tif")

x_info <- rgdal::GDALinfo(my_layers[1])

# Define size of the tile
size <- x_info["res.x"] * 1000

tiles <- GSIF::getSpatialTiles(x_info, block.x = size, return.SpatialPolygons = FALSE)

# i comes from split_predictors.sh
i <- as.numeric(commandArgs(trailingOnly = TRUE))
layer <- my_layers[i]
# Run loop ----------------------------------------------------------------


# Loop takes predictor rasters, splits them up per tile, and saves to disk

for (tile in 1:nrow(tiles))
{
  
  lyr_name <- tools::file_path_sans_ext(basename(layer))
  
  lyr_id <- str_c("tile", tile, "_", lyr_name)
  print(str_glue("Processing {lyr_id}"))
  
  
  output_foldername <- milkunize2(str_glue("Projects/Agriculture_modeling/Data/Predictors_splitted/{lyr_name}"), "archive")
  dir.create(output_foldername, recursive = TRUE, showWarnings = FALSE)
  
  output_filename <- str_glue("{output_foldername}/{lyr_id}.tif")
  

  # plot(x_ras)
  if (!file.exists(output_filename))
  {
    r_load <- rgdal::readGDAL(layer, offset = unlist(tiles[tile, c("offset.y", "offset.x")]),
                              region.dim = unlist(tiles[tile, c("region.dim.y", "region.dim.x")]),
                              output.dim = unlist(tiles[tile, c("region.dim.y", "region.dim.x")]),
                              silent = TRUE)
    
    #### Load tiles as rasters
    x_ras <- raster::raster(r_load)
    
    names(x_ras) <- layer %>% 
      basename() %>% 
      str_remove(".tif")
    
    
    # x_ras

    writeRaster(x_ras, output_filename)
    
  }
}
