#!/bin/bash

#SBATCH --partition=milkun
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name=extract_raster_vals
#SBATCH --mem-per-cpu=48G
#SBATCH --array=1-24
# Standard out and Standard Error output files with the job number in the name.
#SBATCH -o "/Logs/log_extract_presences_%a.out"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=m.cengic@science.ru.nl

export TMPDIR=/scratch/mdls
mkdir -p $TMPDIR

srun /opt/R-3.4.2/bin/R --vanilla --no-save --args ${SLURM_ARRAY_TASK_ID} < /Extract_raster_values.R
