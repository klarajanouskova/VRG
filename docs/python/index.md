---
title: Python & Libraries
---

# Python environment setup

The preferred way to get the wanted versions of Python and libraries like PyTorch is via [modules](http://lmod.readthedocs.io/) + python virtual environments.
First, you load the modules you want, for example

    module load PyTorch/2.5.1-foss-2023b-CUDA-12.4.0

will load PyTorch 2.5.1 and ton of dependencies (shortened output of `module list`)

    Currently Loaded Modules:
     ...  31) Python/3.11.5-GCCcore-13.2.0               ...  76) gmpy2/2.1.5-GCC-13.2.0
     ...  32) cffi/1.15.1-GCCcore-13.2.0                 ...  77) sympy/1.13.1-gfbf-2023b
     ...  33) cryptography/41.0.5-GCCcore-13.2.0         ...  78) Z3/4.13.0-GCCcore-13.2.0
     ...  34) virtualenv/20.24.6-GCCcore-13.2.0          ...  79) CUDA/12.4.0
     ...  35) Python-bundle-PyPI/2023.10-GCCcore-13.2.0  ...  80) cuDNN/9.5.0.50-CUDA-12.4.0
     ...  36) Abseil/20240116.1-GCCcore-13.2.0           ...  81) GDRCopy/2.4-GCCcore-13.2.0
     ...  37) protobuf/25.3-GCCcore-13.2.0               ...  82) UCX-CUDA/1.15.0-GCCcore-13.2.0-CUDA-12.4.0
     ...  38) protobuf-python/4.25.3-GCCcore-13.2.0      ...  83) magma/2.7.2-foss-2023b-CUDA-12.4.0
     ...  39) pybind11/2.11.1-GCCcore-13.2.0             ...  84) NCCL/2.20.5-GCCcore-13.2.0-CUDA-12.4.0
     ...  40) gfbf/2023b                                 ...  85) PyTorch/2.5.1-foss-2023b-CUDA-12.4.0
     ...  41) SciPy-bundle/2023.11-gfbf-2023b            ...
     ...  42) libyaml/0.2.5-GCCcore-13.2.0               ...
     ...  43) PyYAML/6.0.1-GCCcore-13.2.0                ...
     ...  44) GMP/6.3.0-GCCcore-13.2.0                   ...
     ...  45) MPFR/4.2.1-GCCcore-13.2.0                  ...

Among others it has also loaded Python - `Python/3.11.5-GCCcore-13.2.0`.

When you now run

    python --version

you should get 3.11.5. And with the wanted version of PyTorch:

    python -c "import torch; print(torch.__version__)"

## Finding available modules
Run

    module avail

to get all the available modules, or search for a specific one (in this case `Python`)

    module spider Python

More info on [CMP internal page](https://k13133.felk.cvut.cz/cmp/software) or [RCI wiki](https://login.rci.cvut.cz/wiki/modules).

## Installing python packages not included in modules
The standard workflow is to load modules, create python virtual environment, install packages into the virtual environment (e.g. `pip install`).
For example:

    module load PyTorch/2.5.1-foss-2023b-CUDA-12.4.0
    module load torchvision/0.20.1-foss-2023b-CUDA-12.4.0

    # create virtual environment in some/path
    python -m venv some/path

    # activate it
    source some/path/bin/activate

    # install whatever else you need
    pip install einops tqdm

Later when you want to work on the project:

    module load PyTorch/2.5.1-foss-2023b-CUDA-12.4.0
    module load torchvision/0.20.1-foss-2023b-CUDA-12.4.0

    # activate the environment
    source some/path/bin/activate

    python train.py
