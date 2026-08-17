# Unsigned IPA

This workflow intentionally builds an **unsigned** iOS app and packages it as:
`Payload/TimeMarkVN.app` inside `TimeMarkVN.ipa`.

No Apple certificate, provisioning profile, or signing secret is required.

The resulting IPA is intended to be signed later by eSign/another sideload signing workflow.


The workflow uses macos-15 and dynamically selects an installed Xcode 16.x because the XcodeGen-generated project uses project format 77, which Xcode 15.4 cannot open.
