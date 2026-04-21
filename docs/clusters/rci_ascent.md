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

If the modules don't cover your needs (e.g. you need a different PyTorch / CUDA combo, or are testing an unreleased package), you can build a venv from scratch. `uv` is the path of least resistance on aarch64 — it's fast and picks the right wheels:

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

First thing on a fresh allocation, run this minimal CUDA smoke test:

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

## 📚 Example workloads

Small, self-contained scripts that exercise the common model families on a GX10. Each one downloads a tiny checkpoint from Hugging Face, runs a single forward pass / generation, and prints a result — useful both as a smoke test and as a starting template. The CUDA sanity check above is the first one; the rest are collapsed below. Pick whichever model family matches what you're working on.

<details markdown="1">
<summary><code>demo_dino.py</code> — DINOv2 feature extraction, CLS-token cosine similarity</summary>

```python
"""DINOv2 feature-extraction — tiny end-to-end test.

DINO is self-supervised, so there's no classifier head to probe — the
useful output is the patch / CLS embedding. We run two images through
the small variant and print the cosine similarity between their CLS
tokens as a basic sanity check (same image vs. different image).
"""
import torch
import torch.nn.functional as F
from PIL import Image
from io import BytesIO
import urllib.request

from transformers import AutoModel, AutoImageProcessor

# Smallest DINOv2 checkpoint (~22M params). Alternatives:
#   facebook/dinov2-base   (~86M)
#   facebook/dinov2-large  (~300M)
MODEL_ID = "facebook/dinov2-small"

# Two different images — we expect high self-similarity, lower cross-similarity.
IMG_URLS = [
    "http://images.cocodataset.org/val2017/000000039769.jpg",  # cats
    "http://images.cocodataset.org/val2017/000000000285.jpg",  # bear
]


def load(url):
    with urllib.request.urlopen(url) as r:
        return Image.open(BytesIO(r.read())).convert("RGB")


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    print(f"loading {MODEL_ID} on {device} ({dtype})...")
    model = AutoModel.from_pretrained(MODEL_ID, torch_dtype=dtype).to(device).eval()
    processor = AutoImageProcessor.from_pretrained(MODEL_ID)

    images = [load(u) for u in IMG_URLS]
    inputs = processor(images=images, return_tensors="pt").to(device)

    with torch.no_grad():
        out = model(**inputs)

    # last_hidden_state: (B, 1 + num_patches, dim). Index 0 is the CLS token.
    cls = out.last_hidden_state[:, 0].float()
    print("cls embedding shape:", tuple(cls.shape))

    # Pairwise cosine similarity — diagonal = 1.0, off-diagonal should be < 1.
    cls_n = F.normalize(cls, dim=-1)
    sim = (cls_n @ cls_n.T).cpu()
    print("\ncosine similarity matrix:")
    for row in sim.tolist():
        print("  " + "  ".join(f"{v:+.3f}" for v in row))


if __name__ == "__main__":
    main()
```

</details>

<details markdown="1">
<summary><code>demo_siglip2.py</code> — SigLIP2 zero-shot image classification</summary>

```python
"""SigLIP2 zero-shot image classification — tiny end-to-end test.

Pulls a small SigLIP2 checkpoint, runs zero-shot classification on a
single demo image against a handful of text prompts, and prints the
softmax-like probabilities. Good for confirming HF + transformers +
CUDA all play nicely on the Spark.
"""
import torch
from PIL import Image
from io import BytesIO
import urllib.request

from transformers import AutoModel, AutoProcessor

# Small SigLIP2 variant — base/patch16/224 is the lightest "real" one.
# Swap to "google/siglip2-so400m-patch14-384" for the strong (heavy) model.
MODEL_ID = "google/siglip2-base-patch16-224"

# A canonical test image (two cats on a couch). Anything works here.
IMG_URL = "http://images.cocodataset.org/val2017/000000039769.jpg"

# Candidate labels for zero-shot — SigLIP2 expects natural-language prompts.
PROMPTS = [
    "a photo of two cats",
    "a photo of a dog",
    "a photo of a remote control",
    "a photo of a car",
    "a photo of a person",
]


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    print(f"loading {MODEL_ID} on {device} ({dtype})...")
    model = AutoModel.from_pretrained(MODEL_ID, torch_dtype=dtype).to(device).eval()
    processor = AutoProcessor.from_pretrained(MODEL_ID)

    # Fetch the image into memory (avoids needing a local file).
    with urllib.request.urlopen(IMG_URL) as r:
        image = Image.open(BytesIO(r.read())).convert("RGB")

    inputs = processor(
        text=PROMPTS, images=image, padding="max_length", return_tensors="pt"
    ).to(device)

    with torch.no_grad():
        out = model(**inputs)

    # SigLIP uses a sigmoid head per (image, text) pair, not a softmax over
    # labels — so probabilities don't need to sum to 1.
    probs = torch.sigmoid(out.logits_per_image)[0].float().cpu().tolist()

    print("\nzero-shot scores:")
    for prompt, p in sorted(zip(PROMPTS, probs), key=lambda kv: -kv[1]):
        print(f"  {p:.4f}  {prompt}")


if __name__ == "__main__":
    main()
```

</details>

<details markdown="1">
<summary><code>demo_qwen3vl.py</code> — Qwen3-VL image + question → text answer</summary>

```python
"""Qwen3-VL tiny end-to-end test — image + question -> text answer.

Loads a small Qwen3-VL checkpoint, hands it one image and a question,
and prints the generated answer. Sanity check for multimodal chat
templating + generation on the Spark.
"""
import torch
from PIL import Image
from io import BytesIO
import urllib.request

from transformers import AutoProcessor, AutoModelForImageTextToText

# Smallest instruct variant. If this ID 404s, check the Qwen org on HF
# for the current naming (e.g. "Qwen/Qwen3-VL-4B-Instruct").
MODEL_ID = "Qwen/Qwen3-VL-2B-Instruct"

IMG_URL = "http://images.cocodataset.org/val2017/000000039769.jpg"
QUESTION = "Describe this image in one sentence."


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    print(f"loading {MODEL_ID} on {device} ({dtype})...")
    processor = AutoProcessor.from_pretrained(MODEL_ID)
    model = AutoModelForImageTextToText.from_pretrained(
        MODEL_ID, torch_dtype=dtype, device_map=device
    ).eval()

    with urllib.request.urlopen(IMG_URL) as r:
        image = Image.open(BytesIO(r.read())).convert("RGB")

    # Qwen-VL chat format — image goes inline with the user turn.
    messages = [
        {
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": QUESTION},
            ],
        }
    ]

    # apply_chat_template with tokenize=False gives the prompt string;
    # we then re-process with the image to get pixel tensors aligned.
    prompt = processor.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )
    inputs = processor(text=[prompt], images=[image], return_tensors="pt").to(device)

    with torch.no_grad():
        out = model.generate(**inputs, max_new_tokens=128, do_sample=False)

    # Strip the prompt tokens off the front so we only decode the answer.
    new_tokens = out[0, inputs["input_ids"].shape[1]:]
    answer = processor.decode(new_tokens, skip_special_tokens=True)

    print("\nQ:", QUESTION)
    print("A:", answer.strip())


if __name__ == "__main__":
    main()
```

</details>

<details markdown="1">
<summary><code>demo_gemma.py</code> — Gemma-4 text-only + image+text chat turn (gated; needs <code>huggingface-cli login</code>)</summary>

```python
"""Gemma 4 tiny end-to-end test — text-only and image+text chat turns.

Loads the smallest Gemma 4 instruct checkpoint (E2B-it, ~5B params)
and runs two demos against the same model:
  1. text-only chat turn
  2. multimodal chat turn (one image + a question)

Sanity check for processor + chat template + bf16 generation on the
Spark.

Note: Gemma is gated on Hugging Face — accept the license on the
model page and run `huggingface-cli login` first.
"""
import torch
from PIL import Image
from io import BytesIO
import urllib.request

from transformers import AutoProcessor, AutoModelForImageTextToText

# Smallest Gemma 4 instruct variant. Other options in the collection:
#   google/gemma-4-E4B-it    (~8B,  multimodal)
#   google/gemma-4-26B-A4B-it (~27B, MoE)
#   google/gemma-4-31B-it    (~33B, dense)
MODEL_ID = "google/gemma-4-E2B-it"

TEXT_PROMPT = "In one short paragraph, what is an NVIDIA Spark / GB10 system?"

IMG_URL = "http://images.cocodataset.org/val2017/000000039769.jpg"
IMG_QUESTION = "Describe this image in one short sentence."


def generate(model, processor, messages, device, max_new_tokens=200):
    """Run one chat turn through the model and return the decoded reply."""
    inputs = processor.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    ).to(device)

    with torch.no_grad():
        out = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=False,   # greedy for reproducibility
        )

    # Drop the prompt tokens so we only return the model's reply.
    return processor.decode(
        out[0, inputs["input_ids"].shape[1]:], skip_special_tokens=True
    ).strip()


def text_only_demo(model, processor, device):
    messages = [
        {"role": "user", "content": [{"type": "text", "text": TEXT_PROMPT}]},
    ]
    answer = generate(model, processor, messages, device)
    print("\n[text-only]")
    print("Q:", TEXT_PROMPT)
    print("A:", answer)


def image_demo(model, processor, device):
    with urllib.request.urlopen(IMG_URL) as r:
        image = Image.open(BytesIO(r.read())).convert("RGB")

    messages = [
        {
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": IMG_QUESTION},
            ],
        },
    ]
    answer = generate(model, processor, messages, device)
    print("\n[image + text]")
    print("Q:", IMG_QUESTION)
    print("A:", answer)


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    print(f"loading {MODEL_ID} on {device} ({dtype})...")
    processor = AutoProcessor.from_pretrained(MODEL_ID)
    model = AutoModelForImageTextToText.from_pretrained(
        MODEL_ID, torch_dtype=dtype, device_map=device
    ).eval()

    text_only_demo(model, processor, device)
    image_demo(model, processor, device)


if __name__ == "__main__":
    main()
```

</details>

## 🐞 Gotchas

- **`aarch64` wheels.** If `pip install X` is building from source for minutes, there's no aarch64 wheel — either find one, load the module version, or accept the build time.
- **Unified memory ≠ infinite VRAM.** `mem_get_info()` reports shared memory; other processes on the same node eat into your budget.
- **Models gated on HF** (Gemma, some Llamas) need `huggingface-cli login` after you accept the license on the model page.
- **CUDA 13 is new** — very old CUDA-pinned packages may not work. The pre-built modules are a better starting point than pinning old versions.
