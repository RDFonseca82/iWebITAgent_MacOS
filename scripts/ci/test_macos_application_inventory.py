from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def test_legacy_macos_inventory_preserves_versions() -> None:
    collector = source("iWebITService/Components/PrepareFullSyncData.swift")

    assert '"version": versionInfo.version' in collector
    assert '"build": versionInfo.build' in collector
    assert 'forInfoDictionaryKey: "CFBundleShortVersionString"' in collector
    assert 'forInfoDictionaryKey: "CFBundleVersion"' in collector


def test_schema_two_transport_preserves_versions() -> None:
    payload = source("Packages/iWebITCore/Sources/Networking/LegacyAppleAPIClient.swift")

    assert "let version: String?" in payload
    assert "let build: String?" in payload
    assert "version = application.version" in payload
    assert "build = application.build" in payload


def test_v2_collector_collects_bundle_build() -> None:
    collector = source("iWebITService/Telemetry/MacOSDeviceCollectorV2.swift")

    assert 'forInfoDictionaryKey: "CFBundleShortVersionString"' in collector
    assert 'forInfoDictionaryKey: "CFBundleVersion"' in collector
    assert "build: build" in collector


if __name__ == "__main__":
    test_legacy_macos_inventory_preserves_versions()
    test_schema_two_transport_preserves_versions()
    test_v2_collector_collects_bundle_build()
    print("macOS application inventory tests passed.")
