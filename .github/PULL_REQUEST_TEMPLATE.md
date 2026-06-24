## Summary

- 

## Test Plan

- [ ] `scripts/security-check.sh`
- [ ] `bash -n scripts/*.sh`
- [ ] `xcodegen generate`
- [ ] `xcodebuild -project LatteCam.xcodeproj -scheme LatteCam -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

## Security Checklist

- [ ] No real publish passwords, HomeKit PINs, private keys, local certificates, or Scrypted databases are included.
- [ ] No local runbook, real LAN IP, real hostname, device identifier, or pairing state is included.
- [ ] MediaMTX remains authenticated and RTMPS-only for publishing.
- [ ] RTSP remains bound to `127.0.0.1:8554`.
- [ ] Scrypted and MediaMTX are not documented as public internet services.
