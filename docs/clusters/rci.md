---
title: RCI Cluster
parent: Computational Resources
---

# RCI Cluster

A powerful shared compute cluster with 100+ A100 GPUs, accessed via login nodes. Ideal for large experiments, sweeps, and long jobs.

## 🔐 Access

```bash
ssh username@login3.rci.cvut.cz
```
Use login nodes for job submission and environment setup only (they don’t have GPUs).

## 📦 Storage

Refer to [storage info](https://login.rci.cvut.cz/wiki/how_to_start#storage-and-data). Use `/scratch`, `/home`, or `/storage/plzen1/home/username` as appropriate.

## ⚙️ Interactive Jobs

Launch a debugging session:
```bash
srun --partition=interactive --gres=gpu:1 --mpi=pmix --mem 25G --ntasks-per-node=1 --pty bash -i
```

## 📄 Job Submission

Submit with:
```bash
sbatch bash_scripts/my_job.sh
```

Example job script:
```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --output=output.log
#SBATCH --error=error.log
#SBATCH --gres=gpu:1
#SBATCH --mem=25G
#SBATCH --ntasks=1

module load PyTorch/2.5.1-foss-2023b-CUDA-12.4.0
source path/to/my_env/bin/activate
python train.py
```

## 📊 Monitoring Jobs

```bash
squeue | grep username     # Check running jobs
scancel <job_id>          # Cancel job
```

## 📚 Array Jobs

Useful for launching multiple jobs with a single script:

```bash
#!/bin/bash
#SBATCH --job-name=multi_train
#SBATCH --output=logs/out_%A_%a.log
#SBATCH --error=logs/err_%A_%a.log
#SBATCH --array=0-3
#SBATCH --gres=gpu:1
#SBATCH --mem=32G
#SBATCH --ntasks=1

module load PyTorch/2.5.1-foss-2023b-CUDA-12.4.0
source path/to/my_env/bin/activate

# List of configs to run
CONFIGS=("imagenet" "coco" "voc" "laion")

python train.py --dataset ${CONFIGS[$SLURM_ARRAY_TASK_ID]}
```

Submit with:
```bash
sbatch run_array.sh
```

Each job will run `train.py` with a different dataset.

## 🐞 Debugging

- [Jupyter on RCI](https://login.rci.cvut.cz/wiki/jupyter)
- Use interactive jobs for runtime debugging

## 🔄 File Sync

Same options as Non-RCI servers:
- PyCharm deployment
- `rsync`, `scp`, `git`

## ⚙️ Python and Other Software Setup

See [Python environment setup](/docs/python#python-environment-setup).
