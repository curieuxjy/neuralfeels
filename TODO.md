# TODO: Replacing Allegro Hand with a Different Robot Hand

This document outlines the steps required to integrate a different robot hand while maintaining the DIGIT tactile sensors.

---

## Overview

The current NeuralFeels system uses:
- **Allegro Hand**: 4-finger, 16 DOF dexterous hand
- **DIGIT Sensors**: Vision-based tactile sensors mounted on fingertips (4 sensors)
- **RealSense Camera**: RGB-D visual sensor

**Goal**: Replace Allegro Hand with a different robot hand while keeping DIGIT sensors.

---

## Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Trainer                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐  │
│  │   Allegro   │───▶│   Sensor    │───▶│  Neural Model   │  │
│  │  (FK/URDF)  │    │ (DIGIT/RS)  │    │    (SDF)        │  │
│  └─────────────┘    └─────────────┘    └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Integration Guide

### Phase 1: URDF Model Preparation

#### 1.1 Create New Hand URDF
- [ ] Obtain or create URDF for new robot hand
- [ ] Ensure all joint limits, inertia, and collision geometries are defined
- [ ] Place URDF in `data/assets/<new_hand_name>/`

**Reference**: `data/assets/allegro/allegro_digit_left_ball.urdf`

#### 1.2 Attach DIGIT Sensors to Fingertips
- [ ] Add fixed joints for each DIGIT sensor at fingertip links
- [ ] Use the following template for each sensor:

```xml
<!-- Example: DIGIT sensor on index finger -->
<joint name="joint_digit_index" type="fixed">
  <parent link="<index_fingertip_link>"/>
  <child link="digit_index_tip"/>
  <origin xyz="0 0 0.0147" rpy="0 0 1.5708"/>
</joint>

<link name="digit_index_tip">
  <visual>
    <geometry>
      <mesh filename="package://digit.obj"/>
    </geometry>
  </visual>
  <collision>
    <geometry>
      <sphere radius="0.0135"/>
    </geometry>
  </collision>
</link>
```

#### 1.3 Calibrate Sensor Mounting
- [ ] Measure actual DIGIT mounting position on new hand
- [ ] Update `<origin xyz="..." rpy="..."/>` for each sensor joint
- [ ] Verify collision geometry matches physical sensor

**Files to modify**:
```
data/assets/<new_hand>/
├── <new_hand>_digit.urdf      # Main URDF with DIGIT sensors
├── meshes/                     # Hand mesh files (.obj)
└── digit.obj                   # Copy from allegro/
```

---

### Phase 2: Forward Kinematics Module

#### 2.1 Create New Hand Module
- [ ] Copy `neuralfeels/modules/allegro.py` → `neuralfeels/modules/<new_hand>.py`
- [ ] Update class name and imports

#### 2.2 Update Link Mappings
- [ ] Identify new hand's fingertip link names from URDF
- [ ] Update `load_robot()` function:

```python
# In neuralfeels/modules/<new_hand>.py

def load_robot(urdf_file, num_dofs, device="cuda"):
    # Update link names for new hand
    links = {
        "digit_index": "<new_hand_index_tip_link>",
        "digit_middle": "<new_hand_middle_tip_link>",
        "digit_ring": "<new_hand_ring_tip_link>",
        "digit_thumb": "<new_hand_thumb_tip_link>",
    }
    # ... rest of function
```

#### 2.3 Update Joint Configuration
- [ ] Set correct `num_dofs` (number of joints)
- [ ] Update `joint_map` if joint ordering differs from dataset

```python
# Example: joint reordering (if needed)
joint_map = [0, 1, 2, 3, ...]  # Map dataset order → URDF order
```

#### 2.4 Calibrate Frame Transformation
- [ ] Measure transformation from DIGIT gel surface to neural SLAM frame
- [ ] Update `_hora_to_neural()` matrix:

```python
def _hora_to_neural(self):
    """Transform from DIGIT gel reference to neural SLAM frame"""
    # Update this 4x4 transformation matrix based on calibration
    return np.array([
        [r11, r12, r13, tx],
        [r21, r22, r23, ty],
        [r31, r32, r33, tz],
        [0,   0,   0,   1 ]
    ])
```

**Files to create/modify**:
```
neuralfeels/modules/
├── allegro.py          # Original (keep for reference)
├── <new_hand>.py       # New hand module
└── __init__.py         # Add new module import
```

---

### Phase 3: Trainer Integration

#### 3.1 Update Trainer to Use New Hand
- [ ] Modify `neuralfeels/modules/trainer.py`:

```python
# Line ~20: Add import
from neuralfeels.modules.<new_hand> import <NewHand>

# Line ~125-129: Replace Allegro instantiation
self.hand = <NewHand>(
    dataset_path=dataset_path,
    base_pose=base_pose,
    device=self.device,
)
```

#### 3.2 Update FK Query
- [ ] Ensure `get_fk()` returns dict with same keys:
  - `digit_thumb`
  - `digit_index`
  - `digit_middle`
  - `digit_ring`

**Files to modify**:
```
neuralfeels/modules/trainer.py
```

---

### Phase 4: Configuration Updates

#### 4.1 Update Sensor Configuration
- [ ] Modify `scripts/config/main/vitac.yaml` if sensor names change
- [ ] No changes needed if keeping 4 DIGIT sensors

#### 4.2 Update URDF Path References
- [ ] Update visualization script:

```python
# neuralfeels/contrib/urdf/viz.py, Line 18
urdf_path = "data/assets/<new_hand>/<new_hand>_digit.urdf"
```

#### 4.3 Update Dataset Path (if needed)
- [ ] If dataset directory structure changes:

```python
# neuralfeels/modules/sensor.py, Line ~430
seq_dir = os.path.join(root, dataset_path, "<new_hand>", sensor_location)
```

**Files to modify**:
```
scripts/config/main/vitac.yaml
neuralfeels/contrib/urdf/viz.py
neuralfeels/modules/sensor.py (if directory structure changes)
```

---

### Phase 5: Data Collection (For Real-World Use)

#### 5.1 Collect New Dataset
- [ ] Mount DIGIT sensors on new hand
- [ ] Set up RealSense cameras
- [ ] Collect proprioception data (joint states)
- [ ] Save in FeelSight format:

```
data/feelsight_<new_hand>/
├── object_name/
│   └── 00/
│       ├── <new_hand>/           # Tactile data
│       │   ├── thumb/image/
│       │   ├── index/image/
│       │   ├── middle/image/
│       │   └── ring/image/
│       ├── realsense/
│       │   └── front-left/
│       ├── data.pkl              # Joint states, timestamps
│       └── object.mp4
```

#### 5.2 Update Data Loader
- [ ] Ensure `data.pkl` contains correct joint state format
- [ ] Update intrinsics if DIGIT mounting changes FOV

---

### Phase 6: Testing & Validation

#### 6.1 Test FK Computation
```bash
# Test forward kinematics visualization
python neuralfeels/contrib/urdf/viz.py
```
- [ ] Verify all joints move correctly
- [ ] Check DIGIT sensor positions match physical setup

#### 6.2 Test Module Integration
```bash
# Test tactile transformer (sensor-only)
python neuralfeels/contrib/tactile_transformer/touch_vit.py

# Test full pipeline (simulation)
./scripts/run --slam-sim
```

#### 6.3 Validate Accuracy
- [ ] Compare FK output with ground truth poses
- [ ] Check sensor-to-world transformations
- [ ] Verify neural field reconstruction quality

---

## Key Files Summary

| File | Purpose | Modification Required |
|------|---------|----------------------|
| `data/assets/<hand>/*.urdf` | Hand model definition | **Create new** |
| `neuralfeels/modules/<hand>.py` | FK computation | **Create new** |
| `neuralfeels/modules/trainer.py` | Hand instantiation | Update import & init |
| `neuralfeels/contrib/urdf/viz.py` | Visualization | Update URDF path |
| `scripts/config/main/vitac.yaml` | Sensor config | Update if sensors change |
| `neuralfeels/modules/sensor.py` | Data loading | Update if paths change |

---

## Notes

### Supported Hand Types
This integration approach works for hands with:
- 3-5 fingers
- Any number of DOFs
- Fixed DIGIT sensor mounting on fingertips

### DIGIT Sensor Constraints
- Mounting position must allow gel contact with objects
- Sensor orientation affects depth estimation quality
- Minimum 4 sensors recommended for robust tracking

### Performance Considerations
- More DOFs = longer FK computation time
- Consider vectorized FK with `torchkin` for real-time performance

---

## References

- [DIGIT Sensor](https://digit.ml/)
- [torchkin](https://github.com/facebookresearch/theseus/tree/main/theseus/embodied/kinematics)
- [URDF Specification](http://wiki.ros.org/urdf/XML)
- [NeuralFeels Paper](https://suddhu.github.io/neural-feels/)
