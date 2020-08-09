pacman::p_load(Rahat, tidyverse)



folder_extracted <- "Projects/Agriculture_modeling/Data/Changes_csv_extracted" %>% 
  milkunize2("archive")


my_data <- data.table::fread(str_glue("{folder_extracted}/Agrichanges_fit_10_data.csv"))

output_filename_changes <- str_glue("{folder_extracted}/Agrichanges_{category_id}_data.csv")
print(category_id)


load_csv <- function(category, type, folder)
{
  
  if (missing(folder))
  {
    print("missing")
    # Hardcoded folder if one is not specified
    folder <- Rahat::milkunize2("Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted/Single_files", "archive") 
    list.files(folder)
  }
  
  assertthat::assert_that(
    !missing(category),
    !missing(type)
  )
  
  
  # Fork for cross-fitted model
  if (type == "fit")
  {
    file_path <- folder %>% 
      # The pattern is modified here, should probably be only ".csv$"
      # list.files(pattern = "data.csv$", full.names = TRUE) %>% 
      list.files(pattern = ".csv$", full.names = TRUE) %>%
      str_subset(category) %>% 
      str_subset("fit")
    
    #### Load data
    data_loaded <- data.table::fread(file_path[1])
    # Remove rows with NAs
    data_loaded_nona <- tidyr::drop_na(data_loaded)
    # Split data into 2/3rd & 1/3rd
    data_partition <- caret::createDataPartition(data_loaded_nona$PA, p = 0.66, list = FALSE)
    
    # Subset data for training and testing
    train_data <- data_loaded_nona[data_partition, ]
    test_data <- data_loaded_nona[-data_partition, ]
    
    # Put cross validation data into empty list
    data_for_modeling <- list()
    
    data_for_modeling[["training_data"]] <- train_data
    data_for_modeling[["evaluation_data"]] <- test_data
    ####
  }
  # Fork for hindcasted model
  if (type == "eval")
  {
    file_path_fit <- folder %>% 
      list.files(pattern = "data.csv$", full.names = TRUE) %>% 
      str_subset(category) %>% 
      str_subset("fit")
    
    file_path_eval <- folder %>% 
      list.files(pattern = "data.csv$", full.names = TRUE) %>% 
      str_subset(category) %>% 
      str_subset("eval")
    
    #### Load data
    data_loaded_fit <- data.table::fread(file_path_fit)
    data_loaded_eval <- data.table::fread(file_path_eval)
    
    data_loaded_fit_nona <- tidyr::drop_na(data_loaded_fit)
    data_loaded_eval_nona <- tidyr::drop_na(data_loaded_eval)
    
    # Put cross validation data into empty list
    data_for_modeling <- list()
    
    data_for_modeling[["training_data"]] <- data_loaded_fit_nona
    data_for_modeling[["evaluation_data"]] <- data_loaded_eval_nona
    
    
    
  }

  
}


#' Format data for modeling
#'
#' Prepares data for modeling. Gives list with training and evaluation data needed for the model.
#'
#' @param explanatory_variables Raster data, output from \code{get_rasters()}.
#' @param response_variable Data for fitting, output from \code{load_PA()}.
#' @param evaluation_data Data for evaluation, output from \code{load_PA()}. Necessary if \code{cross_validate = FALSE}.
#' @param VIF_select Do VIF selection of predictiors (only works now for \code{cross_validate = TRUE}). Not necessary, since VIF selection is now done a priori.
#' @param cross_validate Assess models on cross validated or hind casted dataset. Default is FALSE.
#' @param threshold Thershold for VIF calculation. Not needed anymore (see \code{VIF_select} arg).
#' @param explanatory_variables_eval Raster stack of explanatory variables used for hind casting. Necessary only if \code{cross_validate = FALSE}.
#'
#' @return List of 2. Training data and evaluation data.
#' @export
#'
#' @examples None.
#' @importFrom raster extract
#' @importFrom tidyr drop_na
#' @importFrom stringr str_detect str_replace
#' @importFrom caret createDataPartition
format_data <- function(explanatory_variables, response_variable, evaluation_data, explanatory_variables_eval,
                        VIF_select = FALSE, cross_validate = FALSE, threshold = 10)
{
  
  if (VIF_select)
  {
    cat(paste0("Performing VIF selection with VIF threshold VIF=", threshold, "..."), "\n")
    explanatory_variables <- vif_select_vars(explanatory_variables, thresh = threshold)
  }
  if (cross_validate == FALSE & missing(explanatory_variables_eval))
  {
    stop("Please add rasters for evaluation if cross_validate = FALSE")
  }
  
  # Extract values from a raster file for modeling
  region_values_raw <- raster::extract(explanatory_variables, response_variable, sp = TRUE)
  region_values <- region_values_raw@data
  
  # Remove points with NA data
  region_data_formatted <- region_values %>%
    tidyr::drop_na()
  
  # Make categorical variables as factor
  categorical_rasters_index <- region_data_formatted %>%
    names() %>%
    stringr::str_detect("catg") %>%
    which()
  
  for (i in 1:length(categorical_rasters_index))
  {
    region_data_formatted[[categorical_rasters_index[i]]] <- as.factor(region_data_formatted[[categorical_rasters_index[i]]])
  }
  # Prepare data for modeling ####
  # Create data partition - in this case cross validated dataset (66% of the data goes to model training)
  
  # Create empty list that will in the end return training and evaluation data
  region_data_for_modeling <- list()
  
  if (cross_validate)
  {
    message("Formatting data for cross-validated model.")
    
    region_data_partition <- caret::createDataPartition(region_data_formatted$PA, p = 0.66, list = FALSE)
    
    # Subset data for training and testing
    region_train_data <- region_data_formatted[region_data_partition,]
    region_test_data <- region_data_formatted[-region_data_partition,]
    
    # Put cross validation data into empty list
    region_data_for_modeling[["training_data"]] <- region_train_data
    region_data_for_modeling[["evaluation_data"]] <- region_test_data
    return(region_data_for_modeling)
    
  } else {
    
    message("Formatting data for hind-casted model.")
    region_values_evaluation_raw <- raster::extract(explanatory_variables_eval, evaluation_data, sp = TRUE)
    region_evaluation_values <- region_values_evaluation_raw@data
    
    # Remove points with NA data
    region_data_evaluation_formatted <- region_evaluation_values %>%
      drop_na()
    
    # Make categorical variables as factor
    categorical_rasters_index <- region_data_evaluation_formatted %>%
      names() %>%
      str_detect("catg") %>%
      which()
    
    for (i in 1:length(categorical_rasters_index))
    {
      region_data_evaluation_formatted[[categorical_rasters_index[i]]] <- as.factor(region_data_evaluation_formatted[[categorical_rasters_index[i]]])
    }
    
  }
  # Put hind casting data into empty list
  region_data_for_modeling[["training_data"]] <- region_data_formatted
  names(region_data_for_modeling[["training_data"]]) <- stringr::str_replace(names(region_data_for_modeling[["training_data"]]), "_fit_catg", "_catg")
  
  region_data_for_modeling[["evaluation_data"]] <- region_data_evaluation_formatted
  names(region_data_for_modeling[["evaluation_data"]]) <- stringr::str_replace(names(region_data_for_modeling[["evaluation_data"]]), "_eval_catg", "_catg")
  
  return(region_data_for_modeling)
}
