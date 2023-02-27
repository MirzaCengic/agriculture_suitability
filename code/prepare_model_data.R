##########################################
####  Prepare data for model fitting
##########################################
#### | Project name: Agriculture modeling
#### | Script type: Data loading
#### | What it does: Load predictors and prepare them for modeling
#### | Date created: November 19, 2019.
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################



# Load packages -----------------------------------------------------------


pacman::p_load(Rahat, tidyverse, raster, sf, data.table)

# r <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/", "archive") %>% 
#   list.files("ESA_urban.t", full.names = TRUE) %>% 
#   raster()
# rr <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_temp/", "archive") %>% 
#   list.files("ESA_urban_polar_eva", full.names = TRUE) %>% 
#   raster()

# plot(r)

# type = "eval"
for (type in c("fit", "eval"))
{
  for (category in c(10, 30, 40)) 
    
  {
    # category = 10
    # type = "fit"
    
    category_id <- str_glue("{type}_{category}")
    
    # Load data ---------------------------------------------------------------
    
    # New folder path
    folder_extracted <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted/Single_files_new" %>%
      milkunize2("archive")

    # Old folder path (working)
    # folder_extracted <- "Projects/Agriculture_modeling/Data/Changes_csv_extracted" %>% 
    #   milkunize2("archive")
    
    files_extracted <- folder_extracted %>% 
      list.files(full.names = TRUE) %>% 
      str_subset(category_id) %>% 
      str_subset("wetland_ex|forest_ex|crops_ex|urban_ex|grassland_ex|crop_distance_ex|urban_distance_ex", negate = TRUE)
    
    out_folder <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted/Combined_files" %>% 
      milkunize2("archive")
    
    
    # output_filename_changes <- str_glue("{out_folder}/Agrichanges_{category_id}_data_gridID.csv")
  
    output_filename_changes <- str_glue("{out_folder}/Agrichanges_{category_id}_data_new.csv")
    print(category_id)
    if (!file.exists(output_filename_changes))
    {
      
      
      
      
      for (i in 2:length(files_extracted))
      {
        print(i)
        
        
        if (i == 2)
        {
          file_extracted <- files_extracted[1] %>% 
            fread() %>% 
            dplyr::select(-grid)
          
          file_extracted2 <- files_extracted[i] %>% 
            fread() %>% 
            dplyr::select(-PA)
          
          file_combined <- bind_cols(file_extracted, file_extracted2)
    
          # tic()
          # file_combined <- file_extracted[file_extracted2, on="grid"]  
          # toc()
          
        } else {
          
          # file_extracted <- files_extracted[1] %>% 
          #   fread()
          # 
          file_extracted2 <- files_extracted[i] %>% 
            fread() %>% 
            dplyr::select(-grid, -PA)
          
          # tic()
          file_combined <- bind_cols(file_combined, file_extracted2)
          
          names(file_combined) <- file_combined %>% 
            names() %>% 
            str_remove(str_glue("_{type}"))
          
          # file_combined <- file_combined[file_extracted2, on="grid"]  
          # toc()
        }
      }
      

      # output_filename_changes
      print(str_glue("Saving {category_id}"))
      fwrite(file_combined, output_filename_changes)
    }
  }
}
# Load raster predictors
# predictors_list <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
#   milkunize2("archive") %>% 
#   list.files(full.names = TRUE) %>% 
#   `[`(c(1:3, 5, 12, 15:21)) %>% 
#   stack()


# Load here the real data on agricultural changes
# Category 30 is the smallest 

# presences_1km <- "Projects/Agriculture_modeling/Data/Changes_vector/" %>% 
#   milkunize2("archive") %>% 
#   list.files(recursive = TRUE, pattern = "30_1km.gpkg", full.names = TRUE) %>% 
#   st_read()



# Develop extract raster from points with SAGA ----------------------------

# in_shape <- milkunize("Projects/Land_use/Data/Shapefile/IMAGE_regions/IMAGE_regions.shp")

# Extract values from polygon (doesn't work for categorical)
# sys_call <- "saga_cmd shapes_grid 2 -POLYGONS:/vol/milkun1/Mirza_Cengic/Projects/Land_use/Data/Shapefile/IMAGE_regions/IMAGE_regions_mollweide.shp -GRIDS:/vol/milkun5/Merit/LU_data/ESA_LC_Mollweide/ESA_test_20km.tif -RESULT:/vol/milkun5/Merit/LU_data/Mollweide_extracted.shp"
# system(sys_call)


# closeSink()


# do the same with saga

# Raster to point...

# Load chimp data for testing
# chimps_vector_path <- "Projects/Agriculture_modeling/model_testing/data/chimps.gpkg" %>% 
  # milkunize2("archive")

# chimps_raster_path <- "Projects/Agriculture_modeling/model_testing/data/chimps_clim.tif" %>% 
  # milkunize2("archive")
# 
# chimps_vector_path_out <- "Projects/Agriculture_modeling/model_testing/data/chimps_out.shp" %>% 
#   milkunize2("archive")
# 
# 
# aa <- raster_to_point_SAGA(in_raster = chimps_raster_path, in_shape = chimps_vector_path, out_shape = chimps_vector_path_out)
# 
# 
# raster_to_point_SAGA <- function(in_raster, in_shape, out_shape)
# {
#   sys_call <- str_glue("saga_cmd shapes_grid 0 -GRIDS:{in_raster} -SHAPES:{in_shape} -RESULT:{out_shape} -RESAMPLING:0")  
#   system(sys_call)
#   # return(st_read(out_shape))
#   
#   lyr_name <- names(raster(in_raster))
# 
#   dat <- out_shape %>%
#     st_read() %>% 
#     rename(
#       layer = lyr_name
#       ) %>% 
#     transmute(
#       x = st_coordinates(.)[, 1],
#       y = st_coordinates(.)[, 2],
#       layer
#     ) %>% 
#     st_set_geometry(NULL) %>% 
#     rename(lyr_name = layer)
#   return(dat)
# }
# 
# aa %>% 
#   mutate(
#     x = st_coordinates(.)[, 1],
#     y = st_coordinates(.)[, 2]
#   ) %>% 
#   st_set_geometry(NULL) %>% 
#   rename(lyr= raster(chimps_raster_path) %>% names()) %>% head
#   dplyr::select()
# 
# 
# aa <- chimps_vector_path %>% 
#   st_read()
# 
# head(aa)
# 
# # sys_call <- "saga_cmd shapes_grid 3 -GRIDS:/vol/milkun5/Merit/LU_data/ESA_LC_Mollweide/ESA_test_20km.tif -SHAPES:/vol/milkun5/Merit/LU_data/Mollweide_20_points.shp"
# # system(sys_call)
# 
# 
# ############################## END ########################################
# pacman::p_load(Rahat, tidyverse, raster, sf)
# 
# category = 10
# type = "fit"
# 
# category_id <- str_glue("{type}_{category}")
# 
# predictors_list <- "Projects/Agriculture_modeling/Data/Predictors_final" %>% 
#   milkunize2("archive") %>% 
#   list.files(full.names = TRUE) %>% 
#   `[`(c(1:3, 5, 12, 15:21))
# 
# presence_files <- "Projects/Agriculture_modeling/Data/Changes_vector" %>% 
#   milkunize2("archive") %>% 
#   list.files(recursive = TRUE, pattern = "1km.gpkg", full.names = TRUE)
# 
# absence_files <- "Projects/Agriculture_modeling/Data/Absences" %>% 
#   milkunize2("archive") %>% 
#   list.files(recursive = TRUE, pattern = ".gpkg$", full.names = TRUE)
# 
# category_id
# 
# absences_sf <- absence_files %>% 
#   str_subset(category_id) %>% 
#   st_read() %>% 
#   transmute(
#     PA = 0
#   )
# 
# presences_sf <- presence_files %>% 
#   str_subset(category_id) %>% 
#   st_read() %>% 
#   transmute(
#     PA = 1
#   )
# 
# 
# agrichanges_sf <- rbind(presences_sf, absences_sf)
# 
# my_presence_file <- presence_files[2]
# 
# # chimps_vector_path_out <- "Projects/Agriculture_modeling/model_testing/data/chimps_out.shp" %>% 
# #   milkunize2("archive")
# 
# output_folder <- "Projects/Agriculture_modeling/Data/Changes_vector_extracted" %>% 
#   milkunize2("archive") 
# 
# i <- 1
# 
# 
# out_layer_name <- predictors_list[i] %>% 
#   str_remove(milkunize2("Projects/Agriculture_modeling/Data/Predictors_final/", "archive")) %>% 
#   str_remove("_fnl.tif")
# 
# my_predictor_file <- predictors_list[i]
# 
# output_file <- str_glue("{output_folder}/{out_layer_name}_extracted_vals.shp")
# 
# 
# raster_to_point_SAGA2 <- function(in_raster, in_shape, out_shape)
# {
#   sys_call <- stringr::str_glue("saga_cmd shapes_grid 0 -GRIDS:{in_raster} -SHAPES:{in_shape} -RESULT:{out_shape} -RESAMPLING:0")  
#   tictoc::tic("Extracting raster values")
#   system(sys_call)
#   tictoc::toc()
# }
# 
# #### Took about 12 minutes
# raster_to_point_SAGA2(in_raster = my_predictor_file, in_shape = my_presence_file, out_shape = output_file)
# 
# aa <- output_file %>% 
#   st_read()
# 
# head(aa)
# 
# 
