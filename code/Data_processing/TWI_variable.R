##########################################
####  Get TWI (topographic wetness index)
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, tictoc)

source("gdal_resample.R")

# Load data ---------------------------------------------------------------

twi_name <- "Projects/Land_use/Data/Predictors/Resampled/TWI_resampled.tif" %>% 
  milkunize2("archive")

twi_norm <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/TWI_norm.tif" %>% 
  milkunize2("archive")


twi_harmonized_name <- "Projects/Agriculture_modeling/Data/Predictors_final/TWI_fnl.tif" %>% 
  milkunize2("archive")

if (!file.exists(twi_harmonized_name))
{

  tic("Resampling TWI")
  GDAL_resample2(infile = twi_norm, outfile = twi_harmonized_name, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  toc()
  
}
