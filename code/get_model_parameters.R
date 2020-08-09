#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=44:00:00
#SBATCH --output "Logs/Get_hyperparameters.log"
#SBATCH --mem=196G
#SBATCH -n 16


##########################################
####  Get optimal ANN model hyperparameters
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Load packages -----------------------------------------------------------
pacman::p_load(raster, sp, sf, caret, Rahat, ranger, mapview, scrubr,caret, janitor,
               data.table, tidyr, tictoc, PresenceAbsence, tidyverse, LUpak, fs)

# Set number of cores
cores_num <- 16

library(doParallel)

# Define parameters -------------------------------------------------------

for (category in c("10", "30", "40"))
{
  for (type in c("fit", "eval"))
  {

    category_id <- str_glue("{type}_{category}")
    
    model_outfolder <- milkunize2("Projects/Agriculture_modeling/Data/Model_output/Model_runs", "archive")
    model_params_outname <- str_glue("{model_outfolder}/Model_parameters_{category_id}.rds")
    
    mdata_folder <- "Projects/Agriculture_modeling/Data/Response_variable/Changes_extracted/Combined_files" %>% 
      milkunize2("archive")
        
    if (!file.exists(model_params_outname))
    {
      
      
      # Load data ---------------------------------------------------------------
      # Load here model data prepared per category and model type
      
      cl <- makePSOCKcluster(cores_num)
      registerDoParallel(cl)
      
      input_fname <- str_glue("{mdata_folder}/Agrichanges_{category_id}_data.csv")
      model_data_raw <- fread(input_fname)
      
      # Modeling setup ----------------------------------------------------------
      
      
      
      # Define here what are the limits for seeking optimal size and decay parameters
      hyperparameter_grid <- expand.grid(size = seq(from = 1, to = 20, by = 1),
                                         decay = c(0.05, 0.01, 
                                                   0.005, 0.001,
                                                   0.0005, 0.0001))
      
      train_control <- trainControl(
        method = "cv", 
        number = 10, 
        p = 75,
        verboseIter = FALSE,
        allowParallel = TRUE
      )
      
      # Store results -----------------------------------------------------------
      ###########################################
      
      model_data <- model_data_raw %>% 
        drop_na() %>% 
        mutate(
          PA = factor(ifelse(PA == 1, TRUE, FALSE), levels = c(TRUE, FALSE))
        )
      
      # Define categorical layers as factor
      categorical_layer_names <- c("ESA.crops", "ESA.forest","ESA.grassland", "ESA.urban", "ESA.wetland", "Protected.areas")
      
      lyr_names <- model_data %>% 
        names()
      
      categorical_layers <- which(lyr_names %in% categorical_layer_names)
      
      # Convert to factorial
      for (i in seq_along(categorical_layers))
      {
        model_data[, categorical_layers[i]] <- as.factor(model_data[, categorical_layers[i]])
      }
      
      model_data_train <- drop_na(model_data)
      # Fit model ---------------------------------------------------------------
      # Run model
      tic(str_glue("Running model for hyperparameter estimation."))
      set.seed(666)
      
      model_nnet <- train(
        PA ~ ., data = model_data_train,
        tuneGrid = hyperparameter_grid,
        trControl = train_control,
        method = "nnet")
      toc()
      stopCluster(cl)
      
      write_rds(model_nnet, model_params_outname)
    }
  }
}
