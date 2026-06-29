# v1.0.80

- Upgraded all 15 Touhou bosses from 8 key frames to 24-frame animation sets.
- Added pose-group frame indexing so boss skills keep their original key poses while playing smoother in-between motion.
- Added a repeatable Touhou boss animation generation script with a `gpt-image-2` attempt path and alpha-preserving local fallback.
- Strengthened sprite cleanup tests, including full 24-frame coverage and Youmu internal white detail preservation.
