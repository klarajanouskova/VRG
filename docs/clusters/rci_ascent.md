---
title: ASUS Ascent GX10 (Blackwell) Nodes
parent: Computational Resources
---

# ASUS Ascent GX10 Nodes — `cantor`, `nash`, `boole`, `cech`

Four ASUS Ascent GX10 workstations (NVIDIA GB10 Grace-Blackwell) are available as direct-access machines, but share the RCI storage. They behave differently from the standard A100 nodes and need a few setup tweaks, so this page collects everything specific to them.

## 🧠 What these machines are

The GX10 is a compact Grace-Blackwell box:

- **CPU + GPU on one module** (NVIDIA GB10 — Arm Grace CPU + Blackwell GPU)
- **`aarch64`** architecture — not x86_64, so binaries and wheels must match
- **Unified memory** (~128 GiB shared between CPU and GPU) — the GPU can address host memory directly, no `.to("cuda")` copies needed for weights that don't fit in a discrete VRAM budget
- **Blackwell features** — native bf16 / fp8, newer tensor-core kernels, CUDA 13
- **Small per-node compute** compared to an A100 node — this is a workstation-class device, not a training monster

### 🎯 Good fits

- **Interactive prototyping** on recent models that assume bf16 / Blackwell (Gemma-4, Qwen3-VL, DINOv2, SigLIP2, …).
- **Inference and light fine-tuning** of mid-sized VLMs / LLMs — the unified memory lets you load models that wouldn't fit on a single 40 GB A100 without sharding.
- **Kernel and `torch.compile` experiments** on Blackwell — flash-attention, xformers, and fp8 paths that aren't yet stable on older hardware.
- **vLLM / diffusers** serving and generation experiments.
- Working on **aarch64 compatibility** of your own code / wheels.

### 🚫 Not a good fit

- Large multi-GPU training runs — use the standard A100 partitions for that.
- Anything that depends on an **x86-only** wheel (a surprising number of older CUDA-prebuilt packages). Check `pip install` output for `manylinux_aarch64` / `linux_aarch64` wheels; otherwise you'll fall back to a slow source build.
- Jobs that just need "a GPU" — leave these nodes free for workloads that actually benefit from Blackwell / unified memory.

## 🔐 Access

Unlike the rest of RCI, these nodes are **accessed directly over SSH** — there is no SLURM, no login node in between, and no job submission. Same VPN / SSH-key setup as the other [Non-RCI Servers](non-rci.html):

```bash
ssh username@cantor.felk.cvut.cz   # or nash / boole / cech
```

Your **RCI storage is mounted** on these machines — `/home`, `/mnt/personal/username`, `/scratch`, and the usual datagrid paths are all reachable, so projects developed on RCI login / A100 nodes work here without copying data around.

Since there's no scheduler, be polite about sharing: check `nvidia-smi` before starting a heavy run, and use `screen` / `tmux` for anything long-running. Confirm you landed on Blackwell:

```bash
nvidia-smi              # expect GB10 / Blackwell, CUDA 13
uname -m                # expect aarch64
```

## 📦 Pre-built Modules (recommended)

A set of `aarch64` + CUDA 13 modules has been compiled centrally and is the **recommended starting point** — they are the fastest way to get a working stack and save you from a long first-time compile of flash-attention / xformers on aarch64.

Available as a base:

- **PyTorch 2.10.0** on **CUDA 13.0.2**
- **torchvision**
- **timm**
- **transformers**
- **flash-attention**
- **xformers**
- **vLLM**
- **diffusers**

Load them, then layer your project-specific packages on top with `pip install` into a venv — the modules just need to be visible to Python when the venv is active. This way you get fast kernels for free and only pay the install cost for your own extras.

## 🧪 Fallback: Fresh pip install

If the modules don't cover your needs (e.g. you need a different PyTorch / CUDA combo, or are testing an unreleased package), you can build a venv from scratch. `uv` is the path of least resistance on aarch64 — it's fast and picks the right wheels. This mirrors the setup used in [`SparkTest/install.sh`](https://github.com/klarajanouskova/SparkTest/blob/main/install.sh):

```bash
# uv is handy here because it's fast on aarch64 and just works
curl -LsSf https://astral.sh/uv/install.sh | sh

uv venv .spark --python 3.12
source .spark/bin/activate

# PyTorch cu130 — this is the critical line (Blackwell needs CUDA 13)
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130

# Everything else normal
uv pip install "transformers>=4.57" accelerate pillow
```

Expect flash-attention / xformers builds from source to take a long time — prefer the modules above unless you really need a custom build.

## ✅ Sanity check

First thing on a fresh allocation, run the minimal CUDA smoke test from `SparkTest/demo.py`:

```python
import torch

print("cuda available:", torch.cuda.is_available())
print("device name:   ", torch.cuda.get_device_name(0))   # NVIDIA GB10
print("cuda runtime:  ", torch.version.cuda)              # 13.0.x
print("torch version: ", torch.__version__)
print("bf16 supported:", torch.cuda.is_bf16_supported())  # True

x = torch.randn(1024, 1024, device="cuda", dtype=torch.bfloat16)
y = x @ x.T
torch.cuda.synchronize()
print("matmul ok, out shape:", tuple(y.shape), "dtype:", y.dtype)

free, total = torch.cuda.mem_get_info()
print(f"vram: {free/2**30:.1f} GiB free / {total/2**30:.1f} GiB total")
```

If `device name` doesn't say GB10 or `cuda runtime` isn't 13.x, your env isn't picking up the right stack — re-check the loaded modules.

## 📚 Example workloads (from `SparkTest`)

The [`SparkTest` repo](https://github.com/klarajanouskova/SparkTest) contains small, self-contained scripts that exercise the common model families on a GX10. Each one downloads a tiny checkpoint from Hugging Face, runs a single forward pass / generation, and prints a result — useful both as a smoke test and as a starting template.

| Script | What it does |
|---|---|
| [`demo.py`](https://github.com/klarajanouskova/SparkTest/blob/main/demo.py) | CUDA + bf16 sanity check (no models) |
| [`demo_dino.py`](https://github.com/klarajanouskova/SparkTest/blob/main/demo_dino.py) | DINOv2 feature extraction, CLS-token cosine similarity |
| [`demo_siglip2.py`](https://github.com/klarajanouskova/SparkTest/blob/main/demo_siglip2.py) | SigLIP2 zero-shot image classification |
| [`demo_qwen3vl.py`](https://github.com/klarajanouskova/SparkTest/blob/main/demo_qwen3vl.py) | Qwen3-VL image + question → text answer |
| [`demo_gemma.py`](https://github.com/klarajanouskova/SparkTest/blob/main/demo_gemma.py) | Gemma-4 text-only + image+text chat turn (gated model — needs `huggingface-cli login`) |

Start with `demo.py` to confirm the environment, then pick whichever model family matches what you're working on.

## 🐞 Gotchas

- **`aarch64` wheels.** If `pip install X` is building from source for minutes, there's no aarch64 wheel — either find one, load the module version, or accept the build time.
- **Unified memory ≠ infinite VRAM.** `mem_get_info()` reports shared memory; other processes on the same node eat into your budget.
- **Models gated on HF** (Gemma, some Llamas) need `huggingface-cli login` after you accept the license on the model page.
- **CUDA 13 is new** — very old CUDA-pinned packages may not work. The pre-built modules are a better starting point than pinning old versions.
