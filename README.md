# TimeMark VN V5 — GitHub Actions Build

## Build unsigned IPA

1. Upload the contents of this ZIP to a GitHub repository.
2. Open **Actions**.
3. Select **Build TimeMark VN V5 Unsigned IPA**.
4. Click **Run workflow**.
5. Wait for the job to finish.
6. Open the completed workflow run.
7. Download artifact **TimeMarkVN-V5-unsigned-IPA**.

The workflow generates the Xcode project with XcodeGen and builds an unsigned
`TimeMarkVN-V5-unsigned.ipa`.

## Important

Unsigned IPA is not installable directly on a normal iPhone. It must be
signed with a valid Apple development/ad-hoc/distribution certificate and
provisioning profile, or installed through a legitimate development/testing
method.

## Requirements

- GitHub repository
- GitHub Actions enabled
- macOS runner
- No Apple certificate is required for this unsigned build

## App permissions

The app requests:
- Camera
- Location while in use
- Photo library read/write

## StoreKit 2

The source contains sample Product IDs:

- `com.timemarkvn.pro.monthly`
- `com.timemarkvn.pro.yearly`
- `com.timemarkvn.pro.lifetime`

These do not become real App Store products until configured in App Store Connect.
