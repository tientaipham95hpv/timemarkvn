# Signed IPA

The workflow builds an Ad Hoc signed IPA suitable for sideloading/eSign.

Required GitHub Actions repository secrets:
- APPLE_CERTIFICATE_BASE64 — base64-encoded Apple Distribution `.p12`
- APPLE_CERTIFICATE_PASSWORD — password for the `.p12`
- PROVISIONING_PROFILE_BASE64 — base64-encoded Ad Hoc `.mobileprovision`
- KEYCHAIN_PASSWORD — temporary password for the CI keychain
- APPLE_TEAM_ID — Apple Developer Team ID

The provisioning profile App ID / bundle identifier must match `CFBundleIdentifier`.
The certificate and provisioning profile must be valid and compatible.
