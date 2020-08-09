##########################################
####  Extract data from rasters
##########################################
#### | Project name: Agriculture modelling 
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Load packages -----------------------------------------------------------

pacman::p_load(Rahat, tidyverse, raster, sf, tictoc)

# Define function
raster_to_point_SAGA2 <- function(in_raster, in_shape, out_shape)
{
  sys_call <- stringr::str_glue("saga_cmd shapes_grid 0 -GRIDS:{in_raster} -SHAPES:{in_shape} -RESULT:{out_shape} -RESAMPLING:0")  
  tictoc::tic("Extracting raster values")
  system(sys_call)
  tictoc::toc()
}

# Run stuff ---------------------------------------------------------------
i <- as.numeric(commandArgs(trailingOnly = TRUE))

# Get predictor list ------------------------------------------------------

predictors_list <- "Projects/Agriculture_modeling/Data/Predictors_final" %>%
  milkunize2("archive") %>%
  list.files(full.names = TRUE)

# Define folder in which the outputs will be stored
output_folder <- "Projects/Agriculture_modeling/Data/Response_variable" %>% 
  milkunize2("archive") 

# Loop
for (type in c("fit", "eval"))
{
  for (category in c(10, 30, 40)) 
    
  {
  
    if (type == "fit") 
    {
      type2 = "eval"
    } 
    if (type == "eval")
    {
      type2 = "fit"
    }
    
    
    predictors_list_clean <- predictors_list %>%
      str_subset("wetland_fnl|forest_fnl|crops_fnl|urban_fnl|grassland_fnl", negate = TRUE) %>% 
      str_subset(type2, negate = TRUE)
    
    my_predictor_file <- predictors_list_clean[i]
    
    out_layer_name <- predictors_list_clean[i] %>%
      str_remove(milkunize2("Projects/Agriculture_modeling/Data/Predictors_final/", "archive")) %>%
      str_remove("_fnl.tif")
    
  category_id <- str_glue("{type}_{category}")
  
  # Define output name for the cleaned geopackage file of the response variable (presences and absences combined)
  #
  agrichanges_path <- str_glue("{output_folder}/Changes_vector/Agrichanges_{category_id}_ppa_grids.shp")
  
  # Use SAGA to extract the values of rasters ----
  
  # Define output filename for extracted values in presences and absences
  output_file <- str_glue("{output_folder}/Changes_vector/Single_files/Agrichanges_{category_id}_{out_layer_name}_extracted_ppa_grids.shp")
  
  if (!file.exists(output_file))
  {
    tic("saga")
    raster_to_point_SAGA2(in_raster = my_predictor_file, in_shape = agrichanges_path, out_shape = output_file)
    toc()
  }
    
}
}
