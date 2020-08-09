##########################################
####  Fit ANN models
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# This is the main script for fitting the ANN model for agriculture modeling project

# Setup script -----------------------------------------------------------
pacman::p_load(raster, sp, sf, caret, Rahat, ranger, mapview, scrubr,caret, janitor,
               tidyr, tictoc, PresenceAbsence, tidyverse, LUpak, fs, data.table)


source("evaluate_ann.R")

# Load data ---------------------------------------------------------------

train_control <- trainControl(
  method = 'none', 
  seeds = 666,
  # classProbs = TRUE,
  verboseIter = TRUE,
  returnData = TRUE)

# Set ANN hyperparameters
# Parameters were determined with get_model_parameters.R script
hyperparams <- expand.grid(size = 20,
            decay = 0.001)


types <- c("fit", "eval") 
categories <- c("10", "30", "40")

i <- as.numeric(commandArgs(trailingOnly = TRUE))

category <- categories[i]

####
model_outfolder <- milkunize2("Projects/Agriculture_modeling/Data/Model_output/Model_runs", "archive")
model_outfolder_eval <- milkunize2("Projects/Agriculture_modeling/Data/Model_output/Evaluations", "archive")

# This is folder with response variable with extracted predictor values
mdata_folder <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted/Combined_files" %>% 
  milkunize2("archive")

####
for (type in types)
{
  category_id <- str_glue("{type}_{category}")
  # Make output folder for each category
  category_outfolder <- str_glue("{model_outfolder}/{category_id}")
  dir.create(category_outfolder, showWarnings = FALSE, recursive = TRUE)
  
  # Fork for model type
  if (type == "fit")
  {
    print(str_glue("Running models for {category}, type {type}"))
    model_outname_fit <- str_glue("{model_outfolder}/Fitted_model_ANN_{category_id}.rds")
    
    if (!file.exists(model_outname_fit))
    {
    # Load here model data prepared per category and model type
      input_fname <- str_glue("{mdata_folder}/Agrichanges_{category_id}_data.csv")
      model_data_raw <- fread(input_fname)
      
    # Set random seed
    set.seed(666)
    # 
    model_data <- model_data_raw %>% 
      drop_na() %>% 
      as_tibble() %>% 
      mutate(
        PA = factor(ifelse(PA == 1, TRUE, FALSE), levels = c(TRUE, FALSE))
      ) %>% 
      group_by(PA) %>% 
      mutate(n = n()) %>% 
      sample_n(
        min(.$n)
      ) %>% 
      ungroup() %>% 
      dplyr::select(-n) %>% 
      as.data.frame()
    
    # Set categorical variables as factors
    categorical_layer_names <- c("ESA_crops", "ESA_forest","ESA_grassland", "ESA_urban", "ESA_wetland", "Protected_areas")
    
    lyr_names <- model_data %>% 
      names()
    
    categorical_layers <- which(lyr_names %in% categorical_layer_names)
    
    # Convert to factorial
    for (j in seq_along(categorical_layers))
    {
      model_data[, categorical_layers[j]] <- factor(model_data[, categorical_layers[1]], levels = c(0, 1))
    }
    #
    names(model_data) <- names(model_data) %>% 
      str_remove(".norm.final.tif")
    
    set.seed(666)
    model_data <- drop_na(model_data)
   
    # Split into train and testing; this is only for fit version of the model.
    # For eval the entire dataset is used for fitting
    # The manuscript refers fit/eval as cross-validation and hindcasting
    
    # Set seed to have reproducible data partitioning
    set.seed(666)
    train_rows <- createDataPartition(model_data$PA, p = 3/4,
                                      list = FALSE)

    model_data_train <- model_data[train_rows, ]
    model_data_test <- model_data[-train_rows, ]
    
    # nrow(model_data_train)
    # nrow(model_data_test)

    # Run model
    print("Fitting model")
    tic(str_glue("Running model for type {type}, category {category}."))
    set.seed(666)
    
    model_nnet <- train(
      PA ~ ., data = model_data_train,
      tuneGrid = hyperparams,
      trControl = train_control,
      method = "nnet")
    toc()
    
    write_rds(model_nnet, model_outname_fit)
    
    print("Evaluating model")
    modeval_fname_fit <- str_glue("{model_outfolder_eval}/Model_evaluation_{category_id}.csv")      
    model_eval <- evaluate_ann_model(model_object = model_nnet, evaluation_data = model_data_test)
    model_eval %>% 
      transmute(
        model_type = category_id,
        TSS, AUC
      ) %>% 
      write_csv(
        modeval_fname_fit
      )
    } else {
      
    # If file exists, then load it and evaluate  
     model_nnet <- read_rds(model_outname_fit)
  
    }
    
   
    if (!file.exists(modeval_fname_fit))
     {
      
      model_eval <- evaluate_ann_model(model_object = model_nnet, evaluation_data = model_data_test)
      model_eval %>% 
        transmute(
          model_type = category_id,
          TSS, AUC
        ) %>% 
        write_csv(
          modeval_fname_fit
        )
      
    }
  }
  
  if (type == "eval")
  {
    print(str_glue("Running models for {category}, type {type}"))
    model_outname_eval <- str_glue("{model_outfolder}/Fitted_model_ANN_{category_id}.rds")
    
    if (!file.exists(model_outname_eval))
    {
    # Load here model data prepared per category and model type
      
      model_data_raw <- fread(input_fname)
      
      mod_data_fit_fname <- str_glue("{mdata_folder}/Agrichanges_fit_{category}_data.csv")
      mod_data_eval_fname <- str_glue("{mdata_folder}/Agrichanges_eval_{category}_data.csv")
    
      
      model_data_fit_raw <- fread(mod_data_fit_fname)
      model_data_eval_raw <- fread(mod_data_eval_fname)
      
      set.seed(666)
      model_fit_data <- model_data_fit_raw %>% 
        drop_na() %>% 
        as_tibble() %>% 
        mutate(
          PA = factor(ifelse(PA == 1, TRUE, FALSE), levels = c(TRUE, FALSE))
        ) %>% 
        group_by(PA) %>% 
        mutate(n = n()) %>% 
        sample_n(
          min(.$n)
        ) %>% 
        ungroup() %>% 
        dplyr::select(-n) %>% 
        as.data.frame()
      
    
      set.seed(666)
      model_eval_data <- model_data_eval_raw %>% 
        drop_na() %>% 
        as_tibble() %>% 
        mutate(
          PA = factor(ifelse(PA == 1, TRUE, FALSE), levels = c(TRUE, FALSE))
        ) %>% 
        group_by(PA) %>% 
        mutate(n = n()) %>% 
        sample_n(
          min(.$n)
        ) %>% 
        ungroup() %>% 
        select(-n) %>% 
        as.data.frame()
      ####
     
      
     
      # Find what layers are categorical and should be factor
      categorical_layer_names <- c("ESA_crops", "ESA_forest","ESA_grassland", "ESA_urban", "ESA_wetland", "Protected_areas")
      lyr_names <- model_fit_data %>% 
        names()
      
      categorical_layers <- which(lyr_names %in% categorical_layer_names)
    
      
    # Convert to factorial
    for (j in seq_along(categorical_layers))
    {
      model_fit_data[, categorical_layers[j]] <- factor(model_fit_data[, categorical_layers[j]], levels = c(0, 1))
      model_eval_data[, categorical_layers[j]] <- factor(model_eval_data[, categorical_layers[j]], levels = c(0, 1))
    }
    
    names(model_eval_data) <- names(model_eval_data) %>% 
        str_remove(".norm.final.tif")
    
    names(model_fit_data) <- names(model_fit_data) %>% 
      str_remove(".norm.final.tif")
    
    # Remove NAs
    # Split into train and testing for the hindcasted models
    model_data_train <- drop_na(model_fit_data)
    model_data_test <- drop_na(model_eval_data)
    
    # For eval the entire dataset is used for fitting
    # Run model
    print("Fitting model")
    tic(str_glue("Running model for type {type}, category {category}."))
    set.seed(666)
    
    model_nnet <- train(
      PA ~ .,
      data = model_data_train,
      tuneGrid = hyperparams,
      trControl = train_control,
      method = "nnet")
    toc()
    
    write_rds(model_nnet, model_outname_eval)
    print("Evaluating model")
    # Save eval
    modeval_fname_eval <- str_glue("{model_outfolder_eval}/Model_evaluation_{category_id}.csv")      
    model_eval <- evaluate_ann_model(model_object = model_nnet, evaluation_data = model_data_test)
    
    model_eval %>% 
      transmute(
        model_type = category_id,
        TSS, AUC
      ) %>% 
      write_csv(
        modeval_fname_eval
      )
    } else {
    
      model_nnet <- read_rds(model_outname_eval)
    }  
  }
}


################################################################


