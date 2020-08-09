##########################################
####  Prepare climate variables
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Steps:
# Load raw chelsa climate data
# log transform one of the layers (12)
# Normalize data
# Resample to target resolution and extent

# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, janitor, tictoc, glue, RStoolbox)

# Load data ---------------------------------------------------------------
# Load raw CHELSA rasters, layers 01, 04, 12, 15.
# These are mean temperature, mean precipitation, temperature variablity, and precipitation coefficient of variation

climate_filenames <- "Data_RAW/Worldclim/current/v2" %>% 
  milkunize2("archive") %>% 
  list.files(full.names = TRUE) %>% 
  str_subset("_01.tif|_04.tif|_12.tif|_15.tif")

climate_raw <- climate_filenames %>% 
  stack()

# Variable 12 is skewed (precipitation)


# Set bioclim 12 as input grid (to log transform)
in_grid <- climate_filenames[3]

out_grid <- "Projects/Agriculture_modeling/Data/Predictors_temp/Worldclim_bio12_logtr.tif" %>% 
  milkunize2("archive")

# "Projects/Agriculture_modeling/Data/Predictors_temp" %>% 
#   milkunize2("archive") %>% 
#   list.files()

# logtransform the precipitation data -------------------------------------


# logtransform the precipitation data 

if (!file.exists(out_grid))
{
  logtr_command <- glue("gdal_calc.py -A {in_grid} --calc \"log10(A+1)\" --type Float32 --outfile {out_grid}")

  system(logtr_command)
  
}
#################

# Load logtransformed layer 12, and replace to regular layer with it 
climate_12_logtr <- raster(out_grid)

climate_raw[[3]] <- climate_12_logtr

names(climate_raw) <- c("wc_bio01", "wc_bio04", "wc_bio12", "wc_bio15")

# Set folder for writing the temporary output. 
# Data from this folder are temporary in nature, and should be deleted afterwards.
out_folder_tmp <- "Projects/Agriculture_modeling/Data/Predictors_temp" %>% 
  milkunize2("archive")


for (lyr in seq_len(nlayers(climate_raw)))
{

  tic(glue("Normalizing layer {lyr}"))
  outname_temp1 <- glue("{out_folder_tmp}/{names(climate_raw[[lyr]])}_temp1.tif")

  if (file.exists(outname_temp1))
  {
    glue("Skipping layer {lyr}")
    next()
  }
    
writeRaster(climate_raw[[lyr]], outname_temp1, options = "COMPRESS=LZW")
  toc()
}
# Normalize (standardize rasters)

## Centering is done in Python

# Resample ----------------------------------------------------------------

source("gdal_resample.R")

# Load normalized layers. NOTE - layer 12 is logtransformed
climate_var_names <- out_folder_tmp %>% 
  list.files(pattern = "norm.tif$", full.names = TRUE)


out_folder_final <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
  milkunize2("archive")

for (i in seq_along(climate_var_names))
{
  # Set name of the layer 
  outlayer_name_fnl <- glue("{out_folder_final}/{names(climate_var_names[i])}.tif")
  
  # Resample layer
  GDAL_resample2(infile = climate_var_names[i], outfile = outlayer_name_fnl, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  
}

########################################################
#### FIN ####
