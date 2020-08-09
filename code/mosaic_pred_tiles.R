##########################################
####  Combine predicted tiles into a mosaic
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Load packages -----------------------------------------------------------
pacman::p_load(Rahat, tidyverse, raster, tictoc)

source("GDAL_mosaic_tile.R")

# Get i parameter from bash script running via slurm (mosaic_pred_tiles.sh)
i <- as.numeric(commandArgs(trailingOnly = TRUE))

categories <- c(10, 30, 40)
types <- c("eval", "fit")

my_ids <- crossing(
  types,   categories) %>% 
  mutate(
    ids = str_c(types, "_", categories)
  )

# my_ids
type <- pull(my_ids[i, 1])

category <- pull(my_ids[i, 2])

category_id <- pull(my_ids[i, 3])

pred_outfolder <- str_glue("Projects/Agriculture_modeling/Data/Model_output/Predictions/Tiled_{category_id}_new") %>% 
  milkunize2("archive")
out_folder_path <- paste0(pred_outfolder, "/*.tif")

outfile <- str_glue("Projects/Agriculture_modeling/Data/Model_output/Prediction_merged_{category_id}_new_april.tif") %>% 
  milkunize2("archive")

# file.remove(outfile )

if (!file.exists(outfile))
{
  
  GDAL_mosaic_tile(output_file = outfile, folder_path = out_folder_path, large_tif = TRUE)
  
}


