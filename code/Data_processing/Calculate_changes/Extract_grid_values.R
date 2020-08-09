#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=6:00:00
#SBATCH --output "Logs/Extract_grid_vals.out"
#SBATCH --mem=20G

##########################################
####  Extract data from rasters for each layer
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Load packages -----------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, sf, tictoc)

# Define function that uses SAGA GIS (quickest algorithm)
raster_to_point_SAGA2 <- function(in_raster, in_shape, out_shape)
{
  sys_call <- stringr::str_glue("saga_cmd shapes_grid 0 -GRIDS:{in_raster} -SHAPES:{in_shape} -RESULT:{out_shape} -RESAMPLING:0")  
  tictoc::tic("Extracting raster values")
  system(sys_call)
  tictoc::toc()
}

# Run stuff ---------------------------------------------------------------

# Get raster mask

bioclim_grid_mask_filename <-  milkunize2("Projects/Agriculture_modeling/Data/grid_mask_1km.tif", "archive")
bioclim_grid_mask <- raster(bioclim_grid_mask_filename)


# Define folder in which the outputs will be stored
output_folder <- "Projects/Agriculture_modeling/Data/Response_variable" %>% 
  milkunize2("archive") 

#### Loop over categories and models

for (type in c("fit", "eval"))
{
  for (category in c(10, 30, 40)) 
    
  {
    category_id <- str_glue("{type}_{category}")
    # Define output name for the cleaned geopackage file of the response variable (presences and absences combined)
    agrichanges_filename <- str_glue("{output_folder}/Changes_vector/Agrichanges_{category_id}_ppa.gpkg")
    
    if (!file.exists(agrichanges_filename))
    {
        # Get rarified presences
      presence_files <- "Projects/Agriculture_modeling/Data/Changes_vector" %>% 
        milkunize2("archive") %>% 
        list.files(recursive = TRUE, pattern = "1km.gpkg", full.names = TRUE)
      
      # Get rarified global absences (PPA = number of presences equal to absences)
      absence_files <- "Projects/Agriculture_modeling/Data/Absences" %>% 
        milkunize2("archive") %>% 
        list.files(recursive = TRUE, pattern = ".gpkg$", full.names = TRUE)
      
      absences_sf <- absence_files %>% 
        str_subset(category_id) %>% 
        st_read() %>% 
        transmute(
          PA = 0
        )
      
      presences_sf <- presence_files %>% 
        str_subset(category_id) %>% 
        st_read() %>% 
        transmute(
          PA = 1
        )
      
      # Get the number of presences and absences
      # If the number is not equal, then subset which ever one there's more, 
      # and combine into PPA dataset
      absences_num <- nrow(absences_sf)
      presences_num <- nrow(presences_sf)
      
      if (!identical(presences_num, absences_num))
      {
        if (presences_num > absences_num)
        {
          presences_sampled <- dplyr::sample_n(presences_sf, absences_num)
          # Combine presences and absences 
          agrichanges_sf <- rbind(presences_sampled, absences_sf)
          st_write(agrichanges_sf, agrichanges_filename)
        }
        if (absences_num > presences_num)
        {
          absences_sampled <- dplyr::sample_n(absences_sf, presences_num)
          # Combine presences and absences 
          agrichanges_sf <- rbind(presences_sf, absences_sampled)
          st_write(agrichanges_sf, agrichanges_filename)
        }
        
      } else 
      {
        # Combine presences and absences 
        agrichanges_sf <- rbind(presences_sf, absences_sf)
        st_write(agrichanges_sf, agrichanges_filename)
      }
    }
    
    # Use SAGA to extract the value of grid ----
    
    # Define output filename for extracted values in presences and absences
    # 
    output_file <- str_glue("{output_folder}/Changes_vector/Agrichanges_{category_id}_ppa_grids.shp")
    
    if (!file.exists(output_file))
    {
      raster_to_point_SAGA2(in_raster = bioclim_grid_mask_filename, in_shape = agrichanges_filename, out_shape = output_file)
    }
    
  }
}

