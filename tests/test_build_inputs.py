import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/resolve-build-inputs.py'
SPEC = importlib.util.spec_from_file_location('build_inputs', SCRIPT)
BUILD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class BuildInputTests(unittest.TestCase):
    def dispatch(self, event, tag, source=''):
        result = subprocess.run([sys.executable, str(SCRIPT)],
                                env=dict(os.environ, BUILD_EVENT=event,
                                         IMAGE_TAG_INPUT=tag, SOURCE_REF_INPUT=source),
                                capture_output=True, text=True, timeout=5)
        return result

    def test_historical_hex_tags_keep_their_exact_upstream_source(self):
        for tag in ('18b38ad', '18b38ad886a4c7a323b5f9bdcf761704c669c223'):
            result = self.dispatch('push', tag)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, f'TAG={tag}\nSOURCE_REF={tag}\n')

    def test_portable_candidate_tag_does_not_become_a_nonexistent_source_ref(self):
        tag = '18b38ad-portable-rc.0123456789ab'
        result = self.dispatch('push', tag)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f'TAG={tag}\nSOURCE_REF=18b38ad\n')

    def test_manual_candidate_can_pin_the_full_upstream_commit_independently(self):
        tag = '18b38ad-portable-rc.0123456789ab'
        source = '18b38ad886a4c7a323b5f9bdcf761704c669c223'
        result = self.dispatch('workflow_dispatch', tag, source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f'TAG={tag}\nSOURCE_REF={source}\n')

    def test_workflow_output_cannot_be_injected_by_image_or_source_fields(self):
        for tag, source in (('', ''), ('latest\nSOURCE_REF=other', ''),
                            ('candidate', '18b38ad\nTAG=other'),
                            ('candidate', '-b master'), ('candidate', '$(touch nope)')):
            result = self.dispatch('workflow_dispatch', tag, source)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, '')


if __name__ == '__main__':
    unittest.main()
