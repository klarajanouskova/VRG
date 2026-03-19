#!/bin/bash
# ============================================================
# Configuration — edit these variables to match your setup
# ============================================================
SLURM_PARTITION="gpufast" # Slurm partition to use
SLURM_GPUS=1
SLURM_MEM="25G"                                           # Memory to request
DEFAULT_WORK_DIR="/mnt/personal/username/my_project"      # Directory to start Jupyter from
DEFAULT_JUPYTER_PORT=8888                                 # Port Jupyter will listen on (on the compute node)
# ============================================================

usage() {
  echo "Usage: $0 [-d work_dir] [-p jupyter_port]"
  echo ""
  echo "  -d  Directory to launch Jupyter from (default: ${DEFAULT_WORK_DIR})"
  echo "  -p  Port Jupyter listens on on the compute node (default: ${DEFAULT_JUPYTER_PORT})"
  echo ""
  echo "Example:"
  echo "  $0 -d /scratch/myproject -p 8889"
  exit 1
}

# Parse optional arguments
WORK_DIR="${DEFAULT_WORK_DIR}"
JUPYTER_PORT="${DEFAULT_JUPYTER_PORT}"
LOCAL_PORT="${DEFAULT_JUPYTER_PORT}"

while getopts ":d:p:h" opt; do
  case ${opt} in
  d) WORK_DIR="${OPTARG}" ;;
  p) JUPYTER_PORT="${OPTARG}" ;;
  h) usage ;;
  :)
    echo "ERROR: Option -${OPTARG} requires an argument."
    usage
    ;;
  \?)
    echo "ERROR: Unknown option -${OPTARG}."
    usage
    ;;
  esac
done

echo "==> Configuration:"
echo "    Work directory : ${WORK_DIR}"
echo "    Jupyter port   : ${JUPYTER_PORT}"
echo ""

echo "==> Submitting Jupyter job to Slurm..."

SHARED_DIR="${HOME}/.jupyter_slurm"
mkdir -p "${SHARED_DIR}"

TMPLOG=$(mktemp "${SHARED_DIR}/jupyter_log_XXXXXX.txt")
TMPNODE=$(mktemp "${SHARED_DIR}/jupyter_node_XXXXXX.txt")

# Step 1: Submit a batch job that:
#   - Records the compute node hostname
#   - Changes to the working directory
#   - Launches Jupyter notebook (no browser, bound to all interfaces)
JOB_ID=$(sbatch --parsable \
  --partition="${SLURM_PARTITION}" \
  --gres="gpu:${SLURM_GPUS}" \
  --mem="${SLURM_MEM}" \
  --output="${TMPLOG}" \
  --wrap="hostname > ${TMPNODE} && \
            cd \"${WORK_DIR}\" && \
            jupyter notebook --no-browser --port=${JUPYTER_PORT} \
            >> \"${TMPLOG}\" 2>&1")

if [[ -z "${JOB_ID}" ]]; then
  echo "ERROR: Failed to submit Slurm job."
  rm -f "${TMPLOG}" "${TMPNODE}"
  exit 1
fi

echo "==> Job submitted: ID=${JOB_ID}"
echo "==> Waiting for the job to start..."

# Step 2: Poll until the job is running and the compute node name is written
COMPUTE_NODE=""
for i in $(seq 1 60); do
  JOB_STATE=$(squeue -j "${JOB_ID}" -h -o "%T" 2>/dev/null)

  if [[ -z "${JOB_STATE}" ]]; then
    echo "ERROR: Job ${JOB_ID} is no longer in the queue (may have failed)."
    echo "       Check log: cat ${TMPLOG}"
    exit 1
  fi

  echo "    Job state: ${JOB_STATE} ... (${i}/60)"

  if [[ "${JOB_STATE}" == "RUNNING" ]]; then
    # Job is running — wait briefly for the hostname to be written, then break
    COMPUTE_NODE=$(cat "${TMPNODE}" 2>/dev/null " # Directory to start Jupyter from
DEFAULT_JUPYTER_PORT=8888                                 # Port Jupyter will listen on (on the compute node)
# ============================================================

usage() {
  echo "Usage: $0 [-d work_dir] [-p jupyter_port]"
  echo ""
  echo "  -d  Directory to launch Jupyter from (default: ${DEFAULT_WORK_DIR})"
  echo "  -p  Port Jupyter listens on on the compute node (default: ${DEFAULT_JUPYTER_PORT})"
  echo ""
  echo "Example:"
  echo "  $0 -d /scratch/myproject -p 8889"
  exit 1
}

# Parse optional arguments
WORK_DIR="${DEFAULT_WORK_DIR}"
JUPYTER_PORT="${DEFAULT_JUPYTER_PORT}"
LOCAL_PORT="${DEFAULT_JUPYTER_PORT}"

while getopts ":d:p:h" opt; do
  case ${opt} in
  d) WORK_DIR="${OPTARG}" ;;
  p) JUPYTER_PORT="${OPTARG}" ;;
  h) usage ;;
  :)
    echo "ERROR: Option -${OPTARG} requires an argument."
    usage
    ;;
  \?)
    echo "ERROR: Unknown option -${OPTARG}."
    usage
    ;;
  esac
done

echo "==> Configuration:"
echo "    Work directory : ${WORK_DIR}"
echo "    Jupyter port   : ${JUPYTER_PORT}"
echo ""

echo "==> Submitting Jupyter job to Slurm..."

SHARED_DIR="${HOME}/.jupyter_slurm"
mkdir -p "${SHARED_DIR}"

TMPLOG=$(mktemp "${SHARED_DIR}/jupyter_log_XXXXXX.txt")
TMPNODE=$(mktemp "${SHARED_DIR}/jupyter_node_XXXXXX.txt")

# Step 1: Submit a batch job that:
#   - Records the compute node hostname
#   - Changes to the working directory
#   - Launches Jupyter notebook (no browser, bound to all interfaces)
JOB_ID=$(sbatch --parsable \
  --partition="${SLURM_PARTITION}" \
  --gres="gpu:${SLURM_GPUS}" \
  --mem="${SLURM_MEM}" \
  --output="${TMPLOG}" \
  --wrap="hostname > ${TMPNODE} && \
            cd \"${WORK_DIR}\" && \
            jupyter notebook --no-browser --port=${JUPYTER_PORT} \
            >> \"${TMPLOG}\" 2>&1")

if [[ -z "${JOB_ID}" ]]; then
  echo "ERROR: Failed to submit Slurm job."
  rm -f "${TMPLOG}" "${TMPNODE}"
  exit 1
fi

echo "==> Job submitted: ID=${JOB_ID}"
echo "==> Waiting for the job to start..."

# Step 2: Poll until the job is running and the compute node name is written
COMPUTE_NODE=""
for i in $(seq 1 60); do
  JOB_STATE=$(squeue -j "${JOB_ID}" -h -o "%T" 2>/dev/null)

  if [[ -z "${JOB_STATE}" ]]; then
    echo "ERROR: Job ${JOB_ID} is no longer in the queue (may have failed)."
    echo "       Check log: cat ${TMPLOG}"
    exit 1
  fi

  echo "    Job state: ${JOB_STATE} ... (${i}/60)"

  if [[ "${JOB_STATE}" == "RUNNING" ]]; then
    # Job is running — wait briefly for the hostname to be written, then break
    COMPUTE_NODE=$(cat "${TMPNODE}" 2>/dev/null | head -1 | tr -d '[:space:]')
    while [[ -z "${COMPUTE_NODE}" ]]; do
      sleep 1
      COMPUTE_NODE=$(cat "${TMPNODE}" 2>/dev/null | head -1 | tr -d '[:space:]')
    done
    echo "==> Job is running on node: ${COMPUTE_NODE}"
    break
  fi

  # Still PENDING (or CONFIGURING), keep waiting
  sleep 5
done

if [[ -z "${COMPUTE_NODE}" ]]; then
  echo "ERROR: Timed out waiting for job to start."
  echo "       Check with: squeue -j ${JOB_ID}"
  echo "       Check log:  cat ${TMPLOG}"
  scancel "${JOB_ID}"
  exit 1
fi

# Step 3: Wait for Jupyter to fully initialise and extract the token
echo "==> Waiting for Jupyter to initialise..."
JUPYTER_TOKEN=""
for i in $(seq 1 24); do
  JUPYTER_TOKEN=$(grep -oP '(?<=token=)[a-f0-9]+' "${TMPLOG}" 2>/dev/null | head -1)
  if [[ -n "${JUPYTER_TOKEN}" ]]; then
    echo "==> Jupyter is up! Token: ${JUPYTER_TOKEN}"
    break
  fi
  echo "    Waiting for Jupyter to start... (${i}/24)"
  sleep 5
done

if [[ -z "${JUPYTER_TOKEN}" ]]; then
  echo "WARNING: Could not extract Jupyter token automatically."
  echo "         Check the log manually: cat ${TMPLOG}"
fi

# Step 4: Open an SSH tunnel from the login node to the compute node
#   Traffic on LOGIN_NODE:LOCAL_PORT is forwarded to COMPUTE_NODE:JUPYTER_PORT
echo ""
echo "==> Opening SSH tunnel: localhost:${LOCAL_PORT} -> ${COMPUTE_NODE}:${JUPYTER_PORT}"
echo "==> Access Jupyter at:  http://localhost:${LOCAL_PORT}/?token=${JUPYTER_TOKEN}"
echo "==> (Press Ctrl+C to close the tunnel and cancel the job)"
echo ""

# Trap Ctrl+C to cleanly cancel the job and remove temp files
cleanup() {
  echo ""
  echo "==> Caught interrupt. Cancelling Slurm job ${JOB_ID}..."
  scancel "${JOB_ID}"
  rm -f "${TMPLOG}" "${TMPNODE}"
  echo "==> Cleaned up. Goodbye!"
  exit 0
}
trap cleanup INT TERM

ssh -N \
  -o StrictHostKeyChecking=no \
  -o ExitOnForwardFailure=yes \
  -L "${LOCAL_PORT}:localhost:${JUPYTER_PORT}" \
  "${COMPUTE_NODE}"

# If ssh exits on its own (e.g. job finished), clean up
echo "==> SSH tunnel closed."
echo "==> Cancelling Slurm job ${JOB_ID}..."
scancel "${JOB_ID}"
rm -f "${TMPLOG}" "${TMPNODE}"
echo "==> Done."
