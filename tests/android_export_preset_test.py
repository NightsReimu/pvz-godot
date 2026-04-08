#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path


EXPORT_PRESETS_PATH = Path("export_presets.cfg")


def assert_contains(text: str, needle: str, message: str) -> None:
    if needle not in text:
        raise AssertionError(message)


def main() -> int:
    text = EXPORT_PRESETS_PATH.read_text(encoding="utf-8")
    assert_contains(text, 'permissions/custom_permissions=PackedStringArray(', "android export preset should declare custom Android permissions")
    assert_contains(text, 'android.permission.INTERNET', "android export preset should request INTERNET so update checks can resolve hosts")
    assert_contains(text, 'android.permission.ACCESS_NETWORK_STATE', "android export preset should request ACCESS_NETWORK_STATE for network diagnostics")
    assert_contains(text, 'android.permission.REQUEST_INSTALL_PACKAGES', "android export preset should request REQUEST_INSTALL_PACKAGES so the in-app updater can hand APK installs to Android")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
