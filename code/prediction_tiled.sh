#!/bin/bash

#SBATCH --partition=milkun
#SBATCH --time=1:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name=tiled_pred
#SBATCH --mem-per-cpu=8G
#SBATCH --array=1-6630%100
# Standard out and Standard Error output files with the job number in the name.
#SBATCH -o "/vol/milkunB/mcengic/Projects/Agriculture_modeling/Output/Logs/Modeling/Tiled_prediction/pred_tile_fit_%a.out"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=m.cengic@science.ru.nl

export TMPDIR=/scratch/mdls
mkdir -p $TMPDIR

srun /opt/R-3.4.2/bin/R --vanilla --no-save --args ${SLURM_ARRAY_TASK_ID} < /vol/milkunB/mcengic/Projects/Agriculture_modeling/Scripts/Model/prediction_tiled.R
