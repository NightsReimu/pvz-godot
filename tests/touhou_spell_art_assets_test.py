"""Check generated production sprites against their recorded originals."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
directory = ROOT / "art/touhou_spell_fx"
manifest = json.loads((directory / "manifest.json").read_text())
prompts = json.loads((ROOT / "docs/touhou-spell-art-prompts.json").read_text())
assert set(manifest["assets"]) == set(prompts["prompts"])
assert len(manifest["assets"]) == 6
for key, data in manifest["assets"].items():
    path = directory / f"{key}.png"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == data["sha256"], key
    with Image.open(path) as image:
        assert image.mode == "RGBA" and list(image.size) == data["size"], key
        alpha = image.getchannel("A")
        assert hashlib.sha256(alpha.tobytes()).hexdigest() == data["alpha_sha256"], key
        histogram = alpha.histogram()
        assert histogram[0] > image.width * image.height * 0.1, key
        assert histogram[255] > 0 and sum(histogram[1:255]) > 0, key
        # The source remains byte-exact, including its feathered transparency.
        assert prompts["transparent_background"] is True
        assert prompts["prompts"][key].strip()
print("Six original RGBA spell illustrations, soft alpha, hashes and prompts: PASS")
