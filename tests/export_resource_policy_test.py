"""Release presets omit development-only assets, keeping all dynamic game art/audio."""
from pathlib import Path
import re, unittest

ROOT=Path(__file__).resolve().parents[1]

class ExportResourcePolicyTest(unittest.TestCase):
    def test_all_platforms_omit_only_development_directories(self):
        config=(ROOT/'export_presets.cfg').read_text()
        presets=re.split(r'\[preset\.\d+\]',config)[1:]
        self.assertEqual(len(presets),4)
        required={'output/**','tmp/**','docs/**','tests/**','scripts/tools/**','art/source_sheets/**','run-game.command'}
        for section in presets:
            exclusions=set(re.search(r'^exclude_filter="([^"]*)"',section,re.M)[1].split(','))
            self.assertEqual(exclusions,required)
            self.assertIn('export_filter="all_resources"',section)
            for directory in ['art/image2','art/vector/fusions','audio','scripts/runtime','scripts/data']:
                self.assertNotIn(directory+'/**',exclusions)

    def test_no_production_loader_reads_excluded_source_sheets_or_developer_assets(self):
        for directory in ['scripts/runtime','scripts/ui','scenes']:
            for path in (ROOT/directory).rglob('*'):
                if path.suffix not in ['.gd','.tscn']:continue
                source=path.read_text()
                self.assertNotRegex(source,r'(?:load|preload|open)\([^\n]*(?:res://(?:tmp|docs|tests|scripts/tools|art/source_sheets)/)',str(path))

if __name__=='__main__':unittest.main()
