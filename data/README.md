<!-- Edited by Jungyeon Lee -->

---
license: mit
language:
- en
pretty_name: FeelSight Dataset
---

# FeelSight: A Visuo-tactile Robot Manipulation Dataset

<div style="text-align: center;">
    <video width="80%" onmouseover="this.pause()" onmouseout="this.play()" autoplay="" loop="" muted="">
        <source src="https://suddhu.github.io/neural-feels/video/dataset_zoom.mp4" type="video/mp4">
    </video>
</div>

The FeelSight dataset contains vision, touch, and proprioception data from in-hand object rotation experiments. It includes **70 experiments** (30 real-world, 40 simulation), each lasting 30 seconds.

For training neural field models, see the [NeuralFeels](https://github.com/facebookresearch/neuralfeels) repository.

---

## Quick Start

### 1. Download the Dataset

```bash
cd data
git clone https://huggingface.co/datasets/suddhu/Feelsight
mv Feelsight/* . && rm -r Feelsight
find . -name "*.tar.gz" -exec tar -xzf {} \; -exec rm {} \;
cd ..
```

### 2. Download Models

**Tactile Transformer:**
```bash
cd data && git clone https://huggingface.co/suddhu/tactile_transformer && cd ..
```

**Segment-Anything (SAM):**
```bash
mkdir -p data/segment-anything && cd data/segment-anything
for model in sam_vit_h_4b8939.pth sam_vit_l_0b3195.pth sam_vit_b_01ec64.pth; do
  gdown https://dl.fbaipublicfiles.com/segment_anything/$model
done
cd ../..
```

### 3. (Optional) Download Tactile Test Data

For testing the tactile transformer independently:

```bash
cd data
gdown https://drive.google.com/drive/folders/1a-8vfMCkW52BpWOPfqk5WM5zsSjBfhN1?usp=sharing --folder
mv sim tacto_data
cd tacto_data && unzip -q '*.zip' && rm *.zip
cd ../..
```

---

## Running Examples

Make sure to activate the environment first:

```bash
conda activate neuralfeels
```

### Module Tests

| Example | Command | Description |
|---------|---------|-------------|
| SAM Segmentation | `python neuralfeels/contrib/sam/test_sam.py` | Tests visual segmentation model |
| Allegro Hand URDF | `python neuralfeels/contrib/urdf/viz.py` | Visualizes robot hand in Open3D |
| Object Mesh Viewer | `python neuralfeels/viz/show_object_dataset.py` | Opens web viewer at http://localhost:8080 |
| Tactile Transformer | `python neuralfeels/contrib/tactile_transformer/touch_vit.py` | Converts touch images to depth (requires tacto_data) |

### Main Experiments

```bash
# Simulation
./scripts/run --slam-sim         # SLAM with rubber duck
./scripts/run --pose-sim         # Pose tracking with Rubik's cube
./scripts/run --occlusion-sim    # Occlusion robustness test

# Real-world
./scripts/run --slam-real        # SLAM with bell pepper
./scripts/run --pose-real        # Pose tracking with large dice
./scripts/run --three-cam        # Three camera baseline
```

---

## Directory Structure

After downloading, your `data/` folder should look like this:

```
data/
├── feelsight/              # Simulation dataset (25GB)
├── feelsight_real/         # Real-world dataset (15GB)
├── feelsight_occlusion/    # Occlusion dataset (11GB)
├── assets/                 # Ground-truth 3D models (2.6GB)
├── segment-anything/       # SAM model weights (4GB)
├── tactile_transformer/    # Tactile depth model (1.2GB)
│   ├── dpt_real.p
│   └── dpt_sim.p
├── tacto_data/             # (Optional) Tactile test images
└── README.md
```

---

## Dataset Details

### Simulation Data

Collected in IsaacGym with TACTO touch simulation.

<div style="text-align: center;">
    <video width="80%" onmouseover="this.pause()" onmouseout="this.play()" autoplay="" loop="" muted="">
        <source src="https://suddhu.github.io/neural-feels/video/feelsight_sim_rubber_duck.mp4" type="video/mp4">
    </video>
</div>

### Real-world Data

Collected from three-camera setup with DIGIT-Allegro hand.

<div style="text-align: center;">
    <video width="80%" onmouseover="this.pause()" onmouseout="this.play()" autoplay="" loop="" muted="">
        <source src="https://suddhu.github.io/neural-feels/video/feelsight_real_bell_pepper.mp4" type="video/mp4">
    </video>
</div>

### Robot Setup

The Allegro hand is mounted on the Franka Emika Panda robot, sensorized with DIGIT tactile sensors and surrounded by three Intel RealSense cameras.

<img src="https://suddhu.github.io/neural-feels/img/robot_cell.jpg" width="90%">

---

## Data Format

```
feelsight/                    # or feelsight_real
├── object_name/              # e.g., 077_rubiks_cube
│   ├── 00/                   # log directory
│   │   ├── allegro/          # tactile sensor data
│   │   │   └── index/        # finger id (thumb, index, middle, ring)
│   │   │       ├── image/    # RGB tactile images (.jpg)
│   │   │       ├── depth/    # ground-truth depth (sim only)
│   │   │       └── mask/     # contact masks (sim only)
│   │   ├── realsense/        # RGB-D camera data
│   │   │   └── front-left/   # camera id
│   │   │       ├── image/    # RGB images (.jpg)
│   │   │       ├── seg/      # segmentation (sim only)
│   │   │       └── depth.npz # depth images
│   │   ├── data.pkl          # proprioception data
│   │   └── object_name.mp4   # sensor stream video
│   └── grasp/                # grasp configuration
└── ...
```

---

## Citation

```bibtex
@article{suresh2024neuralfeels,
  title={{N}eural feels with neural fields: {V}isuo-tactile perception for in-hand manipulation},
  author={Suresh, Sudharshan and Qi, Haozhi and Wu, Tingfan and Fan, Taosha and Pineda, Luis and Lambeta, Mike and Malik, Jitendra and Kalakrishnan, Mrinal and Calandra, Roberto and Kaess, Michael and Ortiz, Joseph and Mukadam, Mustafa},
  journal={Science Robotics},
  pages={adl0628},
  year={2024},
  publisher={American Association for the Advancement of Science}
}
```
