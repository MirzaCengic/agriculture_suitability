##########################################
####  Predict model
##########################################
#### | Project name: Agriculture modeling
#### | Script type: Modeling
#### | What it does: Take set of predictors, split them up in tiles, and predict back
#### | Date created: January 27, 2020.
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################


# Load packages -----------------------------------------------------------

# Load packages -----------------------------------------------------------
# pacman::p_load(Rahat, tidyverse, raster, tictoc, data.table)
pacman::p_load(raster, sp, sf, caret, Rahat, ranger, mapview, scrubr,caret, janitor,
               tidyr, tictoc, PresenceAbsence, tidyverse, LUpak, fs, data.table)

# Load data ---------------------------------------------------------------

# Get the array number (1 to 6630)
# i = 2000
# Tile 5484 is messed up; northness being the culprit
i <- as.numeric(commandArgs(trailingOnly = TRUE))


###########
# Loop takes all of the layers for the given tile, and projects the model prediction on them
# for (i in 1:nrow(tiles))
# {
# i = 666


# model_nnet <- "Projects/Agriculture_modeling/Data/Model_output/Model_runs/fit_10/Model_parameters_fit_10.rds" %>% 
#   milkunize2("archive") %>% 
#   read_rds()


# Predict on the full model
type = "eval"

# for (type in c("fit", "eval"))
# {
# Loop over categories

tile_num <- str_glue("tile{i}_")

###########
# Loop takes all of the layers for the given tile, and projects the model prediction on them
# for (i in 1:nrow(tiles))
# {
# i = 666


# model_nnet <- "Projects/Agriculture_modeling/Data/Model_output/Model_runs/fit_10/Model_parameters_fit_10.rds" %>% 
#   milkunize2("archive") %>% 
#   read_rds()



# for (type in c("fit", "eval"))
# {
# Loop over categories

print(str_glue("Getting predictors for {tile_num}"))
tic("Loading predictors")

output_foldername <- milkunize2("Projects/Agriculture_modeling/Data/Predictors_splitted", "archive")

# my_files <- output_foldername %>% 
#   fs::dir_ls(type = "file", recursive = TRUE)

# aa <- my_files %>% 
#   str_subset("eval", negate = TRUE) %>% 
#   str_subset("wetland_fnl|forest_fnl|crops_fnl|urban_fnl|grassland_fnl|crop_distance_fnl|urban_distance_fnl", 
#              negate = TRUE)

# my_tiled_predictors <- my_files %>% 
#   str_split("/", simplify = TRUE) %>% 
#   `[`(, 9) %>% 
#   unique()

# my_files %>%
#   as_tibble() %>% 
#   rename(filepath = 1) %>% 
# write_csv(milkunize2("Projects/Agriculture_modeling/Data/split_predictors_lists_FE.csv", "archive"))

# There are two "predictors_list" files - one is FE containing tiles with fit/eval data "_lists_FE.csv",
# other one is the old one without the filename extension

predictors_list <- fread(milkunize2("Projects/Agriculture_modeling/Data/split_predictors_lists_FE.csv", "archive"))

# predictors_list
# my_tiles_list <- predictors_list %>% 
#   str_subset("eval", negate = TRUE) %>% 
#   str_subset("wetland_fnl|forest_fnl|crops_fnl|urban_fnl|grassland_fnl|crop_distance_fnl|urban_distance_fnl", 
#              negate = TRUE) %>% 
#   filter(str_detect(filepath, tile_num)) %>% 
#   pull()


my_tiles_list <- predictors_list %>% 
  filter(str_detect(filepath, tile_num)) %>% 
  filter(str_detect(filepath ,"eval", negate = TRUE)) %>% 
  filter(str_detect(filepath, "wetland_fnl|forest_fnl|crops_fnl|urban_fnl|grassland_fnl|crop_distance_fnl|urban_distance_fnl", 
             negate = TRUE)) %>% 
  pull()

predictor_stack <- stack(my_tiles_list)
toc()



# my_tiles_list <- "Projects/Agriculture_modeling/Data/Predictors_splitted/" %>% 
#   milkunize2("archive") %>% 
#   fs::dir_ls(recursive = TRUE, glob = str_glue("*{tile_num}*"))

# predictor_stack <- stack(my_tiles_list)

names(predictor_stack) <- names(predictor_stack) %>%
  str_remove(tile_num) %>% 
  # str_split(tile_num, simplify = TRUE) %>% 
  # `[`(, 2) %>% 
  str_remove(("_fnl")) %>% 
  str_remove("_fit")


# Check if predictor is empty
my_vals <- getValues(predictor_stack[[1]])



if (!all(is.na(my_vals)))
{
  


# toc()

for (category in c(10, 30, 40)) 
{
  
  # category = 10
  # type = "fit"
  # category_id="eval_10"
  category_id <- str_glue("{type}_{category}")
  
  pred_outfolder <- str_glue("Projects/Agriculture_modeling/Data/Model_output/Predictions/Tiled_{category_id}_new") %>% 
    milkunize2("archive")
  outfname <- str_glue("{pred_outfolder}/Predicted_{tile_num}{category_id}.tif")
  
  model_outfolder <- milkunize2(str_glue("Projects/Agriculture_modeling/Data/Model_output/Model_runs"), "archive")
  
  dir.create(pred_outfolder, showWarnings = FALSE)
  
  if (!file.exists(outfname))
  { 
    # list.files(model_outfolder)
     
    print(str_glue("Running modelprediction for {category_id}"))
    model_fname <- str_glue("{model_outfolder}/Fitted_model_ANN_{category_id}_new.rds")
    tic("Loading model")
    model_nnet <- read_rds(model_fname)
    toc()
     
    
    # for (i in 2000:2100)
    # {
    
    
    tic(str_glue("Running {tile_num}"))
    
    
    
    # Set layer names for the raster stack
    layer_names <- names(model_nnet["trainingData"][[1]])[-1]
    # urb <- layer_names[8]
    # urbd <- layer_names[9]
    
    
    # layer 8 is urban distance, layer 9 is urban
    # # names(predictor_stack) <- layer_names
    # names(predictor_stack)[8] <- NA
    # names(predictor_stack)[9] <- NA
    # names(predictor_stack)[8] <- urbd
    # names(predictor_stack)[9] <- urb
    # names(predictor_stack)[8] <- urbd
    
    # plot(predictor_stack[[8:9]])
    # Convert some layers to factorial
    categorical_layer_names <- c("ESA_crops", "ESA_forest","ESA_grassland", "ESA_urban", "ESA_wetland", "Protected_areas")
    lyr_names <- names(predictor_stack)
    
    categorical_layers <- which(lyr_names %in% categorical_layer_names)
    
    # Convert to factorial
    for (j in categorical_layers)
    {
      # print(j)
      predictor_stack[[j]] <- as.factor(predictor_stack[[j]])
    }
    
    ####
    print(str_glue("Predicting for {category_id}..."))
    tic("Predicted in")
    set.seed(666)
    pred_tmp <- predict(predictor_stack, model_nnet, type = "prob")
    writeRaster(pred_tmp, outfname)
    toc()
    toc()
   
    
    print(str_glue("File created for {tile_num}, {category_id}"))
  } else {
    print(str_glue("File exists for {tile_num}, {category_id}"))
  }
  # }
}

}