#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=24:00:00
#SBATCH --output "/Logs/absences_fitl.log"
#SBATCH --mem=96G
#SBATCH -w cn36


##########################################
####  Create absences
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Load packages -----------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, LUpak, foreach, tictoc, sf)

source("reclassify_vals_gdal.R")

# Load data ---------------------------------------------------------------

#############################################
#### Reclassify raster
cores_num <- 40
changes_type = "Fit"


if (changes_type == "Fit")
{
  mybrick <- stack(milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2003-v2.0.7.tif", "data"), 
                   milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2013-v2.0.7.tif", "data"))	
} 
if (changes_type == "Eval")
{
  mybrick <- stack(milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992-v2.0.7.tif", "data"), 
                   milkunize2("ESA_landcover/TIFF/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2003-v2.0.7.tif", "data"))	
}
######################################

x <- mybrick[[1]]
y <- mybrick[[2]]
# Reclassify landcover ----------------------------------------------------

"Projects/Agriculture_modeling/Data/Absences/" %>% 
  milkunize2("archive") %>% 
  dir.create(recursive = TRUE)

basefolder_path <- milkunize2("Projects/Agriculture_modeling/Data/Absences", "archive")


rasterOptions(maxmemory = ncell(mybrick) - 1)

#### Create absences ####

base_folder <- "Projects/Agriculture_modeling/Data/Changes_vector" %>% 
  milkunize2("archive")

exclude_urban = FALSE

########################################
#### Big loop

for (modeling_category in c(10, 30, 40))
{
  
  presences_path <- str_glue("{base_folder}/{changes_type}/Presences/Presence_{tolower(changes_type)}_{modeling_category}_1km.gpkg")
  
  presences_loaded <- st_read(presences_path)
  
  presences_number <- nrow(presences_loaded)
  
  abs_number <- presences_number
  
  
  typefolder_path <- str_glue("{basefolder_path}/{changes_type}/{modeling_category}")
  dir.create(typefolder_path, recursive = TRUE)
  
  raster_out_filename <- str_glue("{basefolder_path}/Absences_{changes_type}_{modeling_category}.tif")
  shape_out_filename <- str_glue("{basefolder_path}/Absences_{changes_type}_{modeling_category}_ppa.gpkg")
  
  
  #### Get change from two rasters ####
  # Check if raster exists and substract two raster if not
  if (!file.exists(raster_out_filename))
  {
    print("Getting change.")
    tic(str_glue("Getting change for {changes_type} {modeling_category}."))
    
    
    if (modeling_category == 10)
    {
      crop_category <- 10:21
    } else {
      crop_category <- as.numeric(modeling_category)
    }
    
    
    values_excluded <- crop_category
    all_categories <- 1:221
    
    # Add fork for cases when the urban areas should be excluded from the absence creation
    if (exclude_urban)
    {
      urban <- 190
      values_excluded <- c(values_excluded, urban, 210:220)
      values_included <- all_categories[-values_excluded]
    } else {
      values_excluded <- c(values_excluded, 210:220)
      values_included <- all_categories[-values_excluded]
    }
    
    
    change_raster <- reclassify_vals_gdal(x = x, y = y, 
                                          outpath = typefolder_path, outfile = raster_out_filename, 
                                          vals_included = values_included, vals_excluded = values_excluded,
                                          category = modeling_category, number_of_cores = cores_num) 
    
   toc()
    
  } else {
    # Load raster otherwise
    change_raster <- raster(raster_out_filename)
  }
  
  
  #### Get change shapefile ####
  # Check if shapefile exists
  if (!file.exists(shape_out_filename)) 
  {
    # Raster to points
    print("Sampling absences.")
    tic(paste0("Raster to points for ", modeling_category))
    # abs_number= 10000
    absences <- raster::sampleRandom(change_raster, abs_number, na.rm = TRUE, sp = TRUE)
    toc()
    absences_sf <- st_as_sf(absences)
    
    names(absences) <- "PA"
    st_write(absences_sf, shape_out_filename)
    
    
    # } else {
    #   absences <- raster::sampleRandom(both, abs_number * multiplyr, na.rm = TRUE, xy = TRUE, df = TRUE)
    #   absences <- absences[, c("x", "y")]
    #   
    #   absences <- sample_n(as.data.frame(absences), abs_number)
    # }
  } else {
    # change_points_sf <- st_read(shape_out_filename)
    print("Done")
  }
  
}

##############################################################################




