from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def test_background_refresh_is_scheduled_on_launch_and_activation() -> None:
    app_delegate = source("iWebITMobile/Sources/App/MobileAppDelegate.swift")

    launch = app_delegate.index("func application(")
    active = app_delegate.index("func applicationDidBecomeActive")
    assert "BackgroundRefreshCoordinator.shared.scheduleRefresh()" in app_delegate[launch:active]
    assert "BackgroundRefreshCoordinator.shared.scheduleRefresh()" in app_delegate[active:]


def test_apns_token_registration_does_not_depend_on_alert_permission() -> None:
    app_delegate = source("iWebITMobile/Sources/App/MobileAppDelegate.swift")

    register = app_delegate.index("application.registerForRemoteNotifications()")
    request = app_delegate.index("requestAuthorization")
    assert register < request


def test_background_launch_waits_for_runtime_configuration() -> None:
    coordinator = source("iWebITMobile/Sources/Background/BackgroundRefreshCoordinator.swift")

    assert "waiting-for-operation" in coordinator
    assert "for _ in 0..<20" in coordinator
    assert "Task.sleep(nanoseconds: 500_000_000)" in coordinator


def test_active_app_has_a_periodic_sync_fallback() -> None:
    runtime = source("iWebITMobile/Sources/App/MobileRuntime.swift")

    assert "foregroundSyncInterval: TimeInterval = 15 * 60" in runtime
    assert "startForegroundSynchronization()" in runtime
    assert "await self.synchronizeIfDue()" in runtime


if __name__ == "__main__":
    test_background_refresh_is_scheduled_on_launch_and_activation()
    test_apns_token_registration_does_not_depend_on_alert_permission()
    test_background_launch_waits_for_runtime_configuration()
    test_active_app_has_a_periodic_sync_fallback()
    print("Mobile background sync tests passed.")
