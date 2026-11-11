---
name: blender-vault-router
description: >-
  Autonomous vault router for the complete 95-skill Blender 3D production suite (~/.agent-sync/vault/blender-skills).
  Routes to vehicle-artist, hard-surface, asset-optimization, materials, rigging, and game export pipelines.
---

# 🎨 Blender Vault Router (95-Skill Production Suite)

This router provides zero-recall access to the comprehensive 95-skill Blender intelligence vault authored by Arjun988, located at `~/.agent-sync/vault/blender-skills/`.

## 🧭 Vault Navigation Map

### 1. Automotive & Hard Surface (Vehicle Pipeline)
- **`vehicle-artist`**: Automotive modeling, proportion blockout, body panel flow, game LOD targets, wheel/suspension assembly.
- **`hard-surface`**: AAA manufacturing logic, boolean cutters (`COL_Booleans`), bevel tiers, panel shut-lines, weighted normals.
- **`blender-modeler`**: Precision Edit Mode, modifiers, collections, manifold mesh cleanup.
- **`asset-optimization`**: Polycount budgets, triangle optimization, draw call reduction.
- **`collision-proxy`**: UCX/UBX collision authoring, convex hulls, physics proxy meshes.

### 2. Materials, Textures & Lookdev
- **`materials`**: PBR node setups (Principled BSDF, roughness, metallic, subsurface).
- **`texture-workflow`**: Normal maps, roughness maps, diffuse/albedo integration.
- **`lookdev`**: Studio HDR lighting, material evaluation, reflections.
- **`uv-workflow`**: Seam placement, UV packing, texel density consistency.

### 3. Rigging & Animation
- **`rigging`**: Armatures, constraints, bone hierarchies, vehicle steering/pitch rigging.
- **`animation`**: Keyframing, graph editor curves, cyclic wheel spin, door actions.

### 4. Game Engine Export
- **`export-pipeline`**: FBX/glTF export with correct axis forward (-Z forward, Y up), scale 1.0, and mesh smoothing.
- **`lod-pipeline`**: LOD0 to LOD3 generation and polycount decimation.

## 🚀 Autonomous Execution Protocol

When any task involves vehicle modeling, 3D mesh sharpening, hard-surface detailing, or Blender operations:
1. Inspect the relevant skill in `~/.agent-sync/vault/blender-skills/<skill-name>/SKILL.md`.
2. Apply the designated non-destructive modifier stack (`Bevel` -> `WeightedNormal`).
3. Enforce **sharp character crease lines** via `Auto Smooth` (30°–45°) or `Mark Sharp` rather than uniform smooth shading.
