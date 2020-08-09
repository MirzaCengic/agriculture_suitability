#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=16:00:00
#SBATCH --output "/Logs/Soil_variables_normalizing.log"
#SBATCH --mem=48G

##########################################
####  Soil variables
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Set up script -----------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, RStoolbox, tictoc, glue)



# Load data ---------------------------------------------------------------

variable_names <- "Projects/Land_use/Data/Predictors/Resampled" %>% 
  milkunize2("archive") %>% 
  list.files(pattern = "Soil_", full.names = TRUE)


for (lyr in seq_along(variable_names))
{
  soil_lyr <- raster(variable_names[lyr])
  
  rasterOptions(maxmemory = ncell(soil_lyr) - 1)
  
  lyr_name <- names(soil_lyr) %>% 
    str_remove_all("_resampled")
  glue("Processing {lyr_name}, iteration {lyr}.")
  lyr_filename <- glue("Projects/Agriculture_modeling/Data/Predictors_intermediate/{lyr_name}_normalized.tif") %>% 
    milkunize2("archive")
  
  if (file.exists(lyr_filename))
  {
    next()
  }
  
  tic(glue("Normalizing {lyr_name}"))
  lyr_normalized <- normImage(soil_lyr, norm = TRUE)
  toc()
  glue("Amount of used memory is {pryr::mem_used() / 1000000} MB")
  
  writeRaster(lyr_normalized, lyr_filename, options = "COMPRESS=LZW")
}


