#!/bin/bash

#SBATCH --partition=milkun
#SBATCH --time=48:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name=modf
#SBATCH --mem-per-cpu=48G
#SBATCH --array=1-3
# Standard out and Standard Error output files with the job number in the name.
#SBATCH -o "/Logs/fit_model_%a.out"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=m.cengic@science.ru.nl

export TMPDIR=/scratch/mdls
mkdir -p $TMPDIR

srun /opt/R-3.4.2/bin/R --vanilla --no-save --args ${SLURM_ARRAY_TASK_ID} < /fit_model.R
