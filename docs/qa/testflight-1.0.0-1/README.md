# HackerQuest 1.0.0 (1) — internal TestFlight delivery

Delivered 2026-11-04. Apple processing and internal availability were verified
through App Store Connect after one upload.

- App: HackerQuest, Apple ID `6830754925`.
- Bundle: `com.colibricodellc.hackerquest`, team `33YM89B48D`.
- Source: `ff99b83a0255ef9a7ff7acd91f7ec38a23e799bb`, merged and pushed on `main`.
- Feature commit: `7f31e2a`; existing boss/companion work was preserved separately
  in `dd19ee6` before integration.
- Version/build: **1.0.0 (1)**, iOS 15+, iPhone and iPad, SDK iOS 27.2.
- Delivery/build UUID: `eba61016-5b4f-4333-b38e-d31c8de046d0`.
- Apple: **VALID / IN_BETA_TESTING**, internal-only audience.
- Group: **Internal iPhone Testing**, two established internal tester accounts,
  exact build assigned, automatic notifications enabled.
- Exact English What to Test notes saved and read back successfully.
- IPA SHA-256: `9d12b4544f6ac18fdb5f08ed4baeef2d44bbe47dc031384bdb669fa28f6c899e`.

[Open TestFlight in App Store Connect](https://appstoreconnect.apple.com/teams/fb21e7ee-d59c-4e90-a8ff-97c884fa4372/apps/6830754925/testflight)

## Retained artifacts and evidence

- Signed IPA: `build/ios/testflight-1.0.0-1/HackerQuest.ipa`.
- Signed archive: `build/ios/archives/HackerQuest-1.0.0-1.xcarchive`.
- Committed-source snapshot and generated Xcode project:
  `build/ios/build1-mobile/` (ignored locally, preserved).
- `artifact-checks.json`: distribution signature, profile/certificate match,
  source manifest, packaged PCK hash, version/bundle/device checks.
- `source-manifest.json`: staged committed source hashes; development MCP
  autoloads and editor plugin excluded from the release snapshot.
- `apple-validation.log`, `apple-upload.log`, `upload-receipt.json`,
  `apple-delivery-status.log`, `apple-status.json`: validation, upload and exact
  post-processing/group/notes readback.
- `local-work-checks.log`, `regression-checks.log`: both new suites plus the five
  existing suites passed. `git diff --check` passed.

## First-delivery setup and verification notes

There was no existing HackerQuest Apple record, bundle ID or export preset. The
release created the app record, explicit bundle ID, matching distribution
profile and internal group, reusing the established two internal tester accounts.
The profile's embedded certificate SHA-1 was matched to the local signing key.
The original credential file was rejected; the working managed credential was
retrieved temporarily and kept outside the repository.

The Mono editor aborted once during threaded resource import; the final source
was imported/exported with the matching non-Mono Godot 4.7.2 editor. The iOS
export required mobile ASTC/ETC2 imports, which are now enabled in the project.
Final renderer tests ran sequentially; an overlapping-window pointer run was
excluded. Apple emitted a nonfatal uploader resume-file warning, followed by
UPLOAD SUCCEEDED. The delivery-status and build APIs independently confirmed
VALID and IN_BETA_TESTING before completion was recorded.

Physical iPhone/iPad touch, safe areas, audio, accessibility, sustained performance
and a full campaign balance playthrough remain acceptance work. Some automated
runs retain Godot shutdown cleanup warnings. The App Store draft remains separate
from this internal delivery and was not submitted for public review.
