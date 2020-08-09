#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=6:00:00
#SBATCH --output "/Logs/Climate_vars_resampling.log"
#SBATCH --mem=32G

##########################################
####  Resample climate variables
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Steps:

# Resample to target resolution and extent

# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, janitor, tictoc, glue, RStoolbox)
# Resample ----------------------------------------------------------------

source("Projects/Agriculture_modeling/R/gdal_resample.R")

out_folder_tmp <- "Projects/Agriculture_modeling/Data/Predictors_intermediate" %>% 
  milkunize2("archive")

# Load normalized layers. NOTE - layer 12 is logtransformed
climate_var_names <- out_folder_tmp %>% 
  list.files(pattern = "wc*.*norm.tif$", full.names = TRUE)


climate_vars <- climate_var_names %>% stack()


out_folder_final <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
  milkunize2("archive")

for (i in seq_along(climate_var_names))
{
  print(i)
  # Set name of the layer 
  outlayer_name_fnl <- glue("{out_folder_final}/{names(climate_vars[[i]])}.tif") %>% 
    str_replace_all("_norm", "_fnl")
  
  if (file.exists(outlayer_name_fnl))
  {
    next()
  }
  # Resample layer
  GDAL_resample2(infile = climate_var_names[i], outfile = outlayer_name_fnl, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
  
}
