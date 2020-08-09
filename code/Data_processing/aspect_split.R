#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=6:00:00
#SBATCH --output "/vol/milkunB/mcengic/Projects/Agriculture_modeling/Output/Logs/Data_processing/Split_aspect.log"
#SBATCH --mem=32G

##########################################
####  Calculate aspect for each tile
##########################################
#### | Project name: Agriculture modelling 
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

pacman::p_load(Rahat, tidyverse, raster, tictoc)

aspect_filename <- "Projects/Agriculture_modeling/Data/Predictors_temp/DEM_aspect.tif" %>% 
  milkunize2("archive")


x_info <- rgdal::GDALinfo(aspect_filename)
# Set size of tiles to calculate aspect for
size <- x_info["res.x"] * 1000

tiles <- GSIF::getSpatialTiles(x_info, block.x = size, return.SpatialPolygons = FALSE)

for (tile in 1:nrow(tiles))
{
  
  lyr_id <- str_c("aspect_tile_", tile)
  
  output_foldername <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/tmp3/aspect")
  output_foldername_cosine <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/tmp3/aspect_cosine")
  

  output_filename <- str_glue("{output_foldername}/{lyr_id}.tif")
  
  if (!file.exists(output_filename))
  {
    r_load <- rgdal::readGDAL(aspect_filename, offset = unlist(tiles[tile, c("offset.y", "offset.x")]),
                              region.dim = unlist(tiles[tile, c("region.dim.y", "region.dim.x")]),
                              output.dim = unlist(tiles[tile, c("region.dim.y", "region.dim.x")]),
                              silent = TRUE)
    
    #### Load tiles as rasters
    x_ras <- raster::raster(r_load)
    # plot(x_ras)
    writeRaster(x_ras, output_filename)
    
    
    aspect_cosine_filename <- str_glue("{output_foldername_cosine}/cosine_{lyr_id}.tif")
    
    if (!file.exists(aspect_cosine_filename))
    {
      # Run GDAL call
      tic("Calculate aspect cosine")
      cosine_call <- glue::glue("gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --overwrite BIGTIFF=YES --type=Float32 -A {output_filename} --calc=\"(cos(A.astype(float)* 3.141592 / 180 ))\" --outfile {aspect_cosine_filename}")
      system(cosine_call)
      toc()
    }
    
  }
}