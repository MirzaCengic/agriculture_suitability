#!/bin/bash


#SBATCH --partition=milkun
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mirzaceng@gmail.com
#SBATCH --time=14-00:00:00
#SBATCH --array=1
#SBATCH --output "/Logs/Crop_distance_calc.log"
#SBATCH --mem=64G
#SBATCH -w cn37

export TMPDIR=/scratch/dist_var
mkdir -p $TMPDIR

srun /opt/R-3.4.2/bin/R --vanilla --no-save --args ${SLURM_ARRAY_TASK_ID} < /Distance_vars/Crop_distance.R
