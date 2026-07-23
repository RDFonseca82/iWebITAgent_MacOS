# Backend contract tests

Fixture-based tests always run with `swift test --package-path
Packages/iWebITCore`.

Read-only live tests are opt-in and require a dedicated synthetic tenant and
device:

```bash
export IWEBIT_CONTRACT_SCRIPT_API_URL=https://agent.iwebit.app/scripts/script_api.php
export IWEBIT_CONTRACT_TEST_IDSYNC=synthetic-test-company
export IWEBIT_CONTRACT_TEST_UNIQUE_ID=synthetic-test-device
swift test --package-path Packages/iWebITCore \
  --filter LiveBackendContractTests
```

The live suite performs only GET requests. Do not configure a production
employee, a real customer tenant, or a device with pending administrative
commands. CI secrets must be scoped to the contract-test environment.

The v2 backend should provide a separate staging base URL and synthetic data.
Once deployed, add enrollment, HMAC rejection, nonce replay, command expiry and
signed-update manifest tests before enabling any v2 remote action.
