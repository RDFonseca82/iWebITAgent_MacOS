# Daemon-owned state and XPC

`AgentStateStore` is the only mutable state store for administrative agent
state. It is instantiated by the privileged macOS service. UI and menu-bar
processes must not open or rewrite the state file.

The launch daemon publishes the `app.iwebit.agent.xpc` Mach service. The
listener accepts only clients whose Apple code signature has the expected Team
ID and one of the allow-listed bundle identifiers.

The XPC surface is intentionally narrow:

- read a redacted typed state;
- request a synchronization;
- submit an APNs token.

Device authentication secrets remain in Keychain and are never returned over
XPC. Future administrative operations should be explicit protocol methods, not
an unrestricted dictionary mutation or shell command.

Before release:

1. add the local `iWebITCore` package to the macOS targets;
2. compile the XPC source files into the service and UI targets;
3. start `AgentXPCService` before the service loop;
4. install the launchd plist with `MachServices`;
5. migrate legacy `appInfo.json` once, then make it read-only or remove it;
6. update the Team ID and final bundle identifiers in one generated build
   configuration, not in multiple source files.
