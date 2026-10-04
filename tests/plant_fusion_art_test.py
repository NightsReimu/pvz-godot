from pathlib import Path
import hashlib, re
import unittest
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
class FusionArtTest(unittest.TestCase):
    def test_models_have_unique_geometry_and_rightward_weapons(self):
        paths = sorted((ROOT/'art/vector/fusions').glob('*.svg'))
        self.assertGreaterEqual(len(paths), 290, 'All new fusion species need separate SVG models')
        signatures = set()
        for path in paths:
            xml = ET.parse(path).getroot()
            self.assertEqual(xml.attrib['viewBox'], '-48 -60 96 112')
            self.assertEqual(xml.attrib['data-facing'], 'right')
            self.assertNotIn('scale(-', path.read_text())
            self.assertGreater(len(list(xml.iter())), 25)
            svg = path.read_text()
            body = svg.split('>', 1)[1].rsplit('</svg>', 1)[0]
            shapes = re.sub(r' (data-[a-z-]+|fill|stroke|stop-color)="[^"]*"', '', body)
            self.assertEqual(hashlib.md5(shapes.encode()).hexdigest(), xml.attrib['data-geometry-signature'], 'Signature must measure actual geometry')
            signatures.add(xml.attrib['data-geometry-signature'])
        self.assertEqual(len(signatures), len(paths), 'Different species need different silhouettes/anatomy')
if __name__ == '__main__': unittest.main()
