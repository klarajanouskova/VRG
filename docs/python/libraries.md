---
title: Libraries
parent: Python & Libraries
---

# Python Libraries for Deep Learning

A quick intro to the Python ecosystem we use for deep learning research and development. Below are the libraries most commonly used in our group projects, along with some additional tools worth knowing.

---

## 🧰 Core Libraries (Used in Most Projects)

### [NumPy](https://numpy.org/)
- Core for array computing, vectorization, indexing, and basic linear algebra.
- Foundation for most ML, AI, and data science libraries.

### [PyTorch](https://pytorch.org/) & [Torchvision](https://pytorch.org/vision/)
- PyTorch is our primary deep learning framework.
- Torchvision provides datasets, transforms, and pre-trained models.
- Also check out [PyTorch Lightning](https://lightning.ai/docs/pytorch/stable/) – a lightweight wrapper for cleaner model code.

### [Torchmetrics](https://lightning.ai/docs/torchmetrics/stable/)
- Standardized metrics for model evaluation, works well with PyTorch Lightning.

### [Matplotlib](https://matplotlib.org/stable/)
- Core library for plotting and visualizations.

### [Seaborn](https://seaborn.pydata.org/)
- Statistical data visualization on top of Matplotlib. Good for grouped bar plots, heatmaps, etc.

### [Pandas](https://pandas.pydata.org/docs/index.html)
- Great for handling table-like data (DataFrames).
- Handy `.to_latex()` export and HDF5 support.
- Basic plotting support via Matplotlib.

### [PIL (Pillow)](https://python-pillow.org/)
- Basic image loading and processing.

### [Hydra](https://hydra.cc/docs/intro/)
- Flexible configuration management system – useful for organizing experiments.

### [Weights & Biases](https://wandb.ai/)
- Experiment tracking, visualization, and collaboration.
- Free student/academic plan available.

---

## 🔍 Other Useful Libraries

These aren’t used all the time, but are great to have in your toolbox:

### [OpenCV](https://opencv.org/)
- Rich set of tools for computer vision and image processing.

### [Timm](https://huggingface.co/docs/timm/index)
- Huge collection of pretrained models, modern architectures, schedulers, and optimizers.

### [OpenMMLab](https://github.com/open-mmlab)
- Modular frameworks for tasks like segmentation, detection, pose estimation, etc.
- Easy to use for training with minimal setup.

### [Hugging Face](https://huggingface.co/)
- Central platform for NLP and vision models, datasets, and tools.
  - [Hub](https://huggingface.co/docs/huggingface_hub/index): for uploading and sharing models (we may start using this for private model repos).

### [SciPy](https://scipy.org/)
- Scientific computing: signal processing, numerical integration, optimization, etc.

### [Plotly](https://plotly.com/python/)
- Interactive, browser-based plots (not built on Matplotlib).
- Great for working with geo or temporal data.

### [Jupyter Notebooks](https://jupyter.org/)
- Interactive Python environment.
- Supports widgets (e.g., `ipywidgets`) – *TODO: Add example notebook*.

### [Albumentations](https://albumentations.ai/)
- Fast and flexible image augmentation library.

### [Kornia](https://kornia.org/)
- Differentiable computer vision and GPU-accelerated data augmentations.

---

> 💡 Feel free to suggest other libraries you find useful — this list evolves with our projects.
