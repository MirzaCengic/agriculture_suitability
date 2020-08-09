#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=4:00:00
#SBATCH --output "/Logs/Previous_lc_calc_FE.log"
#SBATCH --mem=32G

##########################################
####  Previous landcover
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Script setup ------------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, tictoc, glue, janitor)

source("gdal_resample.R")
# Set filenames -----------------------------------------------------------

for (type in c("eval", "fit"))
{

if (type == "fit")
{

  esa_path <- "ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2002-v2.0.7.tif" %>% 
    milkunize2("data")
    
}

  if (type == "eval")
{
  
  esa_path <- "ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992-v2.0.7.tif" %>% 
    milkunize2("data")
  
}


# These are the categories to convert
# m <- c(-Inf, 41, 1,
#        49, 101, 2,
#        109, 154, 3,
#        159, 181, 4,
#        189, Inf, 5)


# Set names ---------------------------------------------------------------

# Define conversion strings -----------------------------------------------

crops <- "2*((A>1)*(A<=42))+1*(A>42)"
forest <- "2*((A>49)*(A<=101))+1*((A<48)*(A>102))"
grassland <- "2*((A>109)*(A<=154))+1*((A<108)*(A>155))"
wetland <- "2*((A>159)*(A<=181))+1*((A<158)*(A>182))"
urban <- "2*(A>=189)+1*(A<188)"

# Define function
reclassify_crops <- function(input, category, type, string, del = FALSE)
{
  outname <- glue("Projects/Agriculture_modeling/Data/Predictors_temp/ESA_{category}_{type}_reclassified.tif") %>% 
    milkunize2("archive")
  
  outname2 <- glue("Projects/Agriculture_modeling/Data/Predictors_temp/ESA_{category}_{type}_binary.tif") %>% 
    milkunize2("archive")
  if (isTRUE(del))
  {
    file.remove(outname2)
    file.remove(outname)
  }
  print(outname)
  
  tic("Running")
  if (!file.exists(outname))
  {
    mystring <- glue::glue("gdal_calc.py -A {input} --outfile={outname} --calc=\"{string}\" --NoDataValue=0")
    system(mystring)
  }
  
  
  if (!file.exists(outname2))
  {
    mystring2 <- glue::glue("gdal_calc.py -A {outname} --outfile={outname2} --calc=\"A-1\" --NoDataValue=-1")
    system(mystring2) 
  }
  
  
  toc()
  
}

# Run functions and reclassify
reclassify_crops(esa_path, "crops", type = type, crops, del = F)
reclassify_crops(esa_path, "forest", type = type, forest, del = F)
reclassify_crops(esa_path, "grassland", type = type, grassland, del = F)
reclassify_crops(esa_path, "wetland", type = type, wetland, del = F)
reclassify_crops(esa_path, "urban", type = type, urban, del = F)

}
# Harmonize ---------------------------------------------------------------

files_list <- "Projects/Agriculture_modeling/Data/Predictors_temp" %>%
  milkunize2("archive") %>%
  list.files(pattern = str_glue("ESA.*._binary"), full.names = TRUE)

for (type in c("eval", "fit"))
{
  for (i in seq_along(files_list))
  {
#   
  outfile_string <- files_list[i] %>%
    str_remove(milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/", "archive")) %>%
    str_remove("_binary.tif")
#   
  layer_harmonized_name <- str_glue("Projects/Agriculture_modeling/Data/Predictors_final/{outfile_string}_fnl.tif") %>%
    milkunize2("archive")
#     
  if (!file.exists(layer_harmonized_name))
    {

    tic("Resampling...")
    GDAL_resample2(infile = files_list[i], outfile = layer_harmonized_name, target_extent = "-180 -57 180 84",
                   target_resolution = "0.002777777777778", method = "bilinear", large_tif = TRUE)
    toc()

    }  
  }
}

