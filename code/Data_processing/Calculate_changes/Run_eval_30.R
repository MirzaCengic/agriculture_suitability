#!/usr/bin/env Rscript

#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=48:00:00
#SBATCH --output /Logs/Get_changes_eval_30.log
#SBATCH -n 20
#SBATCH --mem=20G

library(Rahat)
changes_type <- "Eval"
category <- "30"
n_cores <- 20
script_to_source <- "Get_agri_changes.R"
source(script_to_source)
