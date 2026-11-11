# robot_art_layer — ELE408 Robot Art, modular epicycle layer (v3)

![preview](urdf_preview.png)

## v3: support bars that never turn
Every layer's 500 mm support bar points the same way (world X). Each end has a ball unit that
runs in a U-channel track fixed to the frame (the tracks run along world Y). The motor's
**carriage slides along the bar**, so the motor can be anywhere in the plane but never turns. As a result:
* each motor's reaction torque goes into the frame instead of twisting the arm above
* **joint k sets the absolute direction of arm k**: pen = Σ rₖ (cos qₖ, sin qₖ), so motor k runs at nₖ·ω₀
* the top bearing is passive: pivot k = −joint(k−1)

## Folders
| Folder | What | Use it for |
|---|---|---|
| `cad/RobotArtLayer.FCStd` | FreeCAD file: every part a separate body, grouped by link, with joint markers | editing the design |
| `print/` | the 3 printed parts as STEP + STL, laid flat, centred | slicing and printing |
| `urdf/` | robot description (3 layers + pen + tracks, and a single layer) | Godot / RViz / ROS 2 |
| `meshes/` | one mesh per link (mm, scaled in the URDF) | used by the URDF |
| `matlab/robotart_joint_states.m` | joint values to publish, including the passive slides | MATLAB → ROS 2 |

## Printed parts
| File | Size (mm) | Print orientation |
|---|---|---|
| `ClampA` | 40 x 30 x 41 | boss up (bearing pocket opens upward) |
| `Carriage_MotorCage` | 54 x 54 x 74 | cage front plate on the bed; support under the top plate and the tunnel |
| `ClampB_DriveHub` | 40 x 28 x 36 | clamp on the bed, hub up |

**Carriage:** the bar tunnel is now 20.6 mm square (0.3 mm per side) with no thumb screw. Shallow pockets (0.4 mm deep)
hold strips of **0.5 mm PTFE or UHMW self-adhesive tape**: two 6 mm strips on the floor, two on the roof and a 12 mm strip on each side wall.
The tape stands 0.1 mm proud, so the bar runs on tape with about 0.2 mm clearance. Sand or file the
tunnel lightly if your printer prints holes tight. A V-slot gantry plate with 3–4 V-wheels is the off-the-shelf alternative.

Inserts: M3 heat-set (4.0 mm) in the drive hub, M5 heat-set (6.4 mm) for the clamp thumb screws, M3 grub screw (2.5 mm hole, tap it) in clamp A.

## Bought parts per layer (new in v3)
* 2 × **aluminium U-channel 20 × 10 × 1.5 mm** (17 mm inside) as tracks, cut to length:
  layer 1: ~30 mm (its motor never moves), layer 2: ~370 mm, layer 3: ~710 mm (2 × reach + 30 mm).
  They sit 484 mm apart (centre to centre), with the floor 47.7 mm below the top pivot.
* The ball units at the bar ends ride on the channel floor. The channel walls stop the bar sliding
  along its own length and turning. Ball unit body Ø16 in a 17 mm channel.
* PTFE/UHMW tape (see above).
* A frame to hold the tracks: not modelled.

## Links and joints (per layer i)
| Joint | Type | Parent → child | Notes |
|---|---|---|---|
| `clampA{i}` | fixed | `bar{i-1}` → `clampA{i}` | clamp A at the end of the bar above |
| `pivot{i}` | layer 1 fixed; 2+ continuous, `<mimic joint{i-1} ×−1>` | `clampA{i}` → `motor{i}` | TOP PIVOT, passive 608 bearing |
| `support{i}` | prismatic along X, passive, ±0.214 m | `motor{i}` → `support{i}_bar` | bar centre − carriage centre = −(x of motor i's axis) |
| `joint{i}` | continuous, driven | `motor{i}` → `hub{i}` | BOTTOM PIVOT, motor face; value = arm direction |
| `clampB{i}` | prismatic 0.03–0.17 m | `hub{i}` → `bar{i}` | the next bar slides through clamp B; value = radius |
| `track{i}_L/R_fixed` | fixed | `world` → `track{i}_L/R` | the U-channels |

Layer height is 136.3 mm. The pen is fixed at the end of `bar3`, with its tip on the paper at z = 0.
**Publish from MATLAB:** `joint1..3`, `clampB1..3`, `support1..3`. `robot_state_publisher` computes `pivot2..3` itself.

**Reach limit with 500 mm bars:** for the bottom layer, keep r₁ + r₂ ≤ 214 mm, or that carriage meets a ball unit.

## Build the URDF
```bash
cd urdf
xacro epicycle_layers.urdf.xacro > epicycle_layers.urdf                                  # package:// mesh paths (ROS 2)
xacro epicycle_layers.urdf.xacro mesh_path:=../meshes/ > epicycle_layers_relative.urdf  # relative paths
xacro single_layer.urdf.xacro > single_layer.urdf
```
`robot_art_parts.xacro` holds the shared links (motor, support bar, track); both robot files include it.
Ready-made copies are included.
