---
title: VS Code Remote SSH via Node Allocation
parent: Computational Resources
---

# VS Code Remote SSH to RCI Compute Nodes

When working with VS Code Remote SSH on the RCI cluster, developing directly on the login node is highly discouraged as it consumes shared resources. Instead, you should allocate a dedicated job on a compute node and connect VS Code directly to it.

This tutorial provides a fully automated way to allocate a CPU job on RCI and instantly configure your local SSH so that you can connect via VS Code with a single click.

## Prerequisites

Ensure you have **password-free access** to the RCI login node,  e.g. via SSH keys.

## 1. The Allocation Script (`cpu_rci.bash`)

We will use a bash script on your **local machine** that requests an interactive CPU job on RCI, waits for the allocation to start, and updates a dedicated SSH configuration snippet with the allocated node's hostname.

Save the following script as `cpu_rci.bash` on your local machine (for example in your project folder or `~/.local/bin/`), change the RCI_USER and other parameters as needed, and make it executable (`chmod +x cpu_rci.bash`):

```bash
#!/bin/bash

# ==========================================
# ANTIGRAVITY REMOTE IDE - SLURM ALLOCATOR
# ==========================================

# --- Configuration ---
LOGIN_NODE="login3.rci.cvut.cz"   # RCI login node or SSH alias
USERNAME="cluster_username"               # Your cluster username
TIME="12:00:00"                   # 8 hours requested
PARTITION="amd"                   # Target CPU partition (or `cpu`)
CPUS="2"                          # Number of CPUs requested -- sufficient from my own experience
MEM_PER_CPU="5G"                  # Memory per CPU (Total: 10GB) -- sufficient from my own experience
# ---------------------

# Ensure a persistent temp directory exists in your home for the agents/IDE
ssh $LOGIN_NODE "mkdir -p /home/$USERNAME/.tmp_remote"

echo "Submitting an $TIME CPU allocation on partition '$PARTITION'..."
echo "Resources: $CPUS CPUs, $MEM_PER_CPU memory per CPU."

# 1. Submit a sleeper job via sbatch (Forced login shell)
JOB_SUBMIT=$(ssh $LOGIN_NODE "bash -lc 'sbatch --parsable --partition=$PARTITION --time=$TIME --cpus-per-task=$CPUS --mem-per-cpu=$MEM_PER_CPU --wrap=\"sleep $TIME\"'")
JOB_ID=$(echo "$JOB_SUBMIT" | awk '{print $1}')

if [ -z "$JOB_ID" ]; then
    echo "Error: Failed to submit job. Check your connection to '$LOGIN_NODE'."
    exit 1
fi

echo "Job $JOB_ID submitted. Waiting for node allocation..."

# 2. Poll the cluster until the job starts running
while true; do
    STATE=$(ssh $LOGIN_NODE "bash -lc 'squeue -j $JOB_ID -h -o %T'")
    
    if [ "$STATE" == "RUNNING" ]; then
        COMPUTE_NODE=$(ssh $LOGIN_NODE "bash -lc 'squeue -j $JOB_ID -h -o %N'")
        break
    elif [ "$STATE" == "PENDING" ]; then
        echo "Job is PENDING. Waiting 5 seconds..."
        sleep 5
    else
        echo "Job state is '$STATE'. Something went wrong."
        exit 1
    fi
done

echo "Success! Allocated Compute Node: $COMPUTE_NODE"

# 3. Update the SSH config with the new rci_cpu alias
cat <<EOF > ~/.ssh/rci_cluster.conf
Host rci_cpu
    HostName $COMPUTE_NODE
    User $USERNAME
    ProxyJump $LOGIN_NODE
    StrictHostKeyChecking no
    # Force remote agents to use your home directory for temporary data
    SetEnv TMPDIR=/home/$USERNAME/.tmp_remote
EOF

echo "======================================================"
echo "🎉 Configuration complete!"
echo "1. Open VS-Code (or Antigravity)'s Remote Window."
echo "2. Connect to: rci_cpu"
echo ""
echo "⚠️  REMINDER: When finished, release the node by running:"
echo "ssh $LOGIN_NODE \"bash -lc 'scancel $JOB_ID'\""
echo "======================================================"%    
```

## 2. Including the Config in SSH

The script dynamically rewrites `~/.ssh/rci_cluster.conf` every time you run it. For your local SSH client (and therefore VS Code) to recognize the newly generated `rci_cpu` host, you must **include** this configuration file in your main SSH settings.

Open your main `~/.ssh/config` file on your local machine:
```bash
nano ~/.ssh/config
```

And add the `Include` directive at the **very top** of the file:
```ssh-config
Include ~/.ssh/rci_cluster.conf

# ... the rest of your normal ~/.ssh/config below ...
```

### What does this config do?
When `cpu_rci.bash` successfully runs, it places the following content into `~/.ssh/rci_cluster.conf`:
```ssh-config
Host rci_cpu
    HostName a12  # (This changes dynamically to whichever node Slurm allocates)
    ProxyJump username@login3.rci.cvut.cz
    User username
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```
- **`Host rci_cpu`**: This defines a static alias (`rci_cpu`) that will be permanently visible in your VS Code Remote-SSH list.
- **`HostName <node>`**: The actual internal cluster hostname (e.g., `n45`) assigned by Slurm.
- **`ProxyJump`**: It tells SSH to securely tunnel your connection through the RCI login node to reach the internal compute node.
- **`StrictHostKeyChecking no` / `UserKnownHostsFile`**: These lines prevent SSH from throwing security warnings ("man-in-the-middle") when the underlying node for `rci_cpu` changes between different Slurm allocations.

## 3. Seamless VS Code Connection

With the setup complete, your workflow becomes extremely simple:

1. Open a local terminal and run the script:
   ```bash
   ./cpu_rci.bash
   ```
2. Wait a moment for it to say `VS Code Host: rci_cpu (maps to <node>)`.
3. Open VS Code, press `F1`, and select **Remote-SSH: Connect to Host...**
4. Choose **`rci_cpu`** from the list.

VS Code will now connect transparently through the login node directly into the allocated compute node. All your extensions, terminal commands, and python processes in that VS Code window will run securely on the dedicated resource without overloading the login node!

> **Note:** Once you are done, you can cancel the job to free up the node early by logging into RCI and running `scancel <JOB_ID>`, or simply let it expire after the allocated time.

If you are working and the job expires, just run the cpu_rci.bash again and click retry to connect. Sometimes multiple retries might be needed to get the connection through.
