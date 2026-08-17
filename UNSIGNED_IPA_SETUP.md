# Unsigned IPA

This workflow intentionally builds an **unsigned** iOS app and packages it as:
`Payload/TimeMarkVN.app` inside `TimeMarkVN.ipa`.

No Apple certificate, provisioning profile, or signing secret is required.

The resulting IPA is intended to be signed later by eSign/another sideload signing workflow.
