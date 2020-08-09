##########################################
####  Evaluate ANN models
##########################################
#### | Project name: Agricultural modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Function
evaluate_ann_model <- function(model_object, evaluation_data)
{
  model_test_prediction <- predict(object = model_object, newdata = evaluation_data, type = "prob")
  
  observed_events <- evaluation_data %>% 
    mutate(
      PA = ifelse(PA == TRUE, 1, 0)
    ) %>% 
    pull()
  
  
  predicted_probs <- model_test_prediction[, 1]
  
  eval_data <- data.frame(
    ID = 1:nrow(evaluation_data),
    Observed = ifelse(evaluation_data$PA == TRUE, 1, 0),
    Predicted = model_test_prediction[, 1])
  
  best_thres <- PresenceAbsence::optimal.thresholds(eval_data, opt.methods = 3)$Predicted
  
  # Get vector of predicted values at presence and absence locations
  # Prepare dataframe for dismo::evaluate function
  predicted <- data.frame(
    ID = 1:nrow(evaluation_data),
    Observed = ifelse(evaluation_data$PA == TRUE, "P", "A"),
    Predicted = model_test_prediction[, 1]) %>%
    tidyr::spread(Observed, Predicted) %>%
    dplyr::select(-ID)
  
  presence_values <- predicted %>%
    dplyr::select(P) %>%
    tidyr::drop_na() %>%
    dplyr::pull()
  absence_values <- predicted %>%
    dplyr::select(A) %>%
    tidyr::drop_na() %>%
    dplyr::pull()
  
  model_evaluation <- dismo::evaluate(p = presence_values, a = absence_values, model = fitted_model, tr = best_thres)
  
  # Calculate TSS (TSS = sensitivity + specificity - 1) ####
  # Extract values from slots
  TSS <- model_evaluation@TPR + model_evaluation@TNR - 1
  AUC <- model_evaluation@auc
  # Create data for final output
  model_evaluation <- data.frame("AUC" = AUC, "TSS" = TSS, row.names = NULL)
  return(model_evaluation)
}
