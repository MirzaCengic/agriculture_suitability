#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=6:00:00
#SBATCH -o "Logs/extracted_to_csv.out"
#SBATCH --mem=32G


##########################################
####  Convert extracted values of explanatory variables to csv
##########################################
#### | Project name: Agriculutre modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# This script takes the output of Changes_calc/Extract_raster_values.R script, 
# converts the values to csv, and combines those csv's into a single file per category and evaluation type.

# Load packages -----------------------------------------------------------
pacman::p_load(raster, sp, sf, caret, Rahat, ranger, mapview, scrubr,caret, janitor,
               tidyr, tictoc, PresenceAbsence, tidyverse, LUpak, fs)

# Load data ---------------------------------------------------------------

# Updated the folder in which the files with extracted values are located.

# Input files
extracted_files_list <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_vector/Single_files" %>% 
  milkunize2("archive") %>% 
  list.files(pattern = "Agrichanges.*ppa_grids.shp$", recursive = TRUE, full.names = TRUE)


####
# Folder for extracted files (output folder)
folder_extracted <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted" %>% 
  milkunize2("archive")

for (file in rev(extracted_files_list))
{
  layer_name_temp <- file %>% 
    str_remove("Projects/Agriculture_modeling/Data/Response_variable/Changes_vector/Single_files/" %>% 
                 milkunize2("archive")) %>% 
    str_remove("_extracted_ppa_grids.shp") %>%
    str_remove("Agrichanges_")
  
  layer_type <- layer_name_temp %>% 
    as_tibble() %>% 
    separate(
      value,
      into = c("type", "category"), sep = "_"
    )
  
  # Get the name of the layer, without the category type
  layer_name <- layer_name_temp %>% 
    str_remove("fit_") %>%
    str_remove("eval_") %>% 
    str_sub(start = 4, end = nchar(layer_name_temp))
  

  output_file_name <- str_glue("{folder_extracted}/Single_files_new/Agrichanges_{layer_type$type}_{layer_type$category}_{layer_name}_extracted_ppa_grids.csv")
  
  if (!file.exists(output_file_name))
  {
    
      my_file <- file %>%
        st_read()  
  
    my_file_df <- my_file %>%
      st_set_geometry(NULL)
    
    names(my_file_df)[2] <- "grid"
    names(my_file_df)[3] <- layer_name
    data.table::fwrite(my_file_df, output_file_name)
    print(str_glue("Saving {layer_type$type}_{layer_type$category}_{layer_name}"))

  } else {
    print(str_glue("File exists for {layer_type$type}_{layer_type$category}_{layer_name}"))
    
  }
  
}
