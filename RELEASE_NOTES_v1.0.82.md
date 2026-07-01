# v1.0.82

- Refined Youmu's `gpt-image-2` boss frames so the shared canvas stays stable and the sprite no longer jitters between differently cropped frames.
- Reduced Youmu's in-game draw scale to avoid the oversized look introduced by the previous image2 animation pass.
- Tightened Youmu's skill frame selection so dash, slash, wraith, and finale states animate within coherent frame ranges instead of jumping between unrelated poses.
- Preserved Youmu's white hair, outfit, and half-phantom while softening only the outer sticker-like edge fringe.
- Updated the Touhou boss image2 generation script so targeted reruns keep the full 15-boss metadata record.
