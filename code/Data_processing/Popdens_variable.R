##########################################
####  Population density
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, glue, RStoolbox)

source("gdal_resample.R")

# Load data ---------------------------------------------------------------

# Load GPW population density file

pop_filename <- "Projects/LU_data/Original/Human_population/gpw-v4-population-density-2000/gpw-v4-population-density_2000.tif" %>% 
  milkunize2("archive")

pop_raw <- pop_filename %>% 
  raster()

# logtransform the population data -------------------------------------
# Set input and output filenames

in_grid <- pop_filename

out_grid <- "Projects/Agriculture_modeling/Data/Predictors_temp/Human_density_logtr.tif" %>% 
  milkunize2("archive")

if (!file.exists(out_grid))
{
  logtr_command <- glue("gdal_calc.py -A {in_grid} --calc \"log10(A+1)\" --type Float32 --outfile {out_grid}")
  system(logtr_command)
  
}

# Load the logtransformed variable
pop_logtr <- out_grid %>% 
  raster()

# Normalize
pop_norm <- normImage(pop_logtr, norm = TRUE)

popnorm_outname <- "Projects/Agriculture_modeling/Data/Predictors_intermediate/Human_density_normalized.tif" %>% 
  milkunize2("archive")

if (!file.exists(popnorm_outname))
{
  writeRaster(pop_norm, popnorm_outname, options = "COMPRESS=LZW")
}


# Resample ----------------------------------------------------------------

out_folder_final <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
  milkunize2("archive")

  # Set name of the layer 
outlayer_name_fnl <- glue("{out_folder_final}/Pop_density_fnl.tif")

if (!file.exists(outlayer_name_fnl))
{
  # Resample layer
  GDAL_resample2(infile = popnorm_outname, outfile = outlayer_name_fnl, target_extent = "-180 -57 180 84",
                 target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
}

