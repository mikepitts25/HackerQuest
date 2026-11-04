# HackerQuest internal iOS delivery

Apple app: HackerQuest (`6830754925`)
Bundle ID: `com.colibricodellc.hackerquest`
Apple team: Colibri Code LLC (`33YM89B48D`)
Distribution profile: `HackerQuest App Store Colibri`
Internal audience: `Internal iPhone Testing` (the two established internal accounts)

The first delivery is version **1.0.0, build 1**. See
`docs/qa/testflight-1.0.0-1/` for the artifact and Apple receipts. The signed IPA
and archive are retained under the ignored `build/ios/` directory.

## Release procedure

1. Update the version/build in `export_presets.cfg` and tester notes in
   `docs/submission/`. Commit and merge the intended source onto `main`.
2. Run `tools/check_fun_pass.sh --preview` and `tools/check_local_work.sh --preview`
   **sequentially**. Native renderer windows can interfere with each other's
   pointer/focus tests. Tests use isolated user-data profiles.
3. Use a matching non-Mono Godot 4.7.2 editor for import/export. The local Mono
   editor can abort in its threaded resource importer. Set `GODOT_BIN` when
   running the QA scripts. Keep `textures/vram_compression/import_etc2_astc=true`:
   Godot requires mobile texture imports for the iOS exporter.
4. Snapshot committed source with
   `python3 tools/prepare_ios_release.py build/ios/<delivery>/source`.
   The snapshot excludes developer/test/build files and strips MCP development
   autoloads and the editor plugin. Its source manifest records the exact commit
   and SHA-256 of every staged file. Never overwrite an old snapshot.
5. Import the snapshot, then export the `iOS` preset with `--export-release`.
   `application/export_project_only=true` produces an Xcode project for a separate
   archive/export step. Run `prepare_ios_release.py` with `--sanitize-plist` on
   its generated Info.plist to remove unused empty permission descriptions.
6. Archive the generated `HackerQuest` scheme for generic iOS, Release, with
   manual distribution signing. Pin the certificate SHA-1 embedded in the chosen
   active provisioning profile. Export using `app-store-connect`, the same
   profile, `manageAppVersionAndBuildNumber=false`, and
   `testFlightInternalTestingOnly=true`.
7. Verify the IPA signature, bundle/version/build, distribution entitlement,
   certificate/profile match, staged-source manifest and packaged PCK hash.
   Record the IPA SHA-256. Keep all private keys outside the repository.
8. Validate with Apple, upload once, retain the delivery receipt, and poll that
   exact build until processing is `VALID`. Read back its internal-group
   membership, tester count, beta state and exact What to Test notes.

A successful upload is separate from completed Apple processing and internal
availability. TestFlight delivery does not establish physical-device touch,
accessibility, audio, thermals, performance, or complete campaign balance.
Internal delivery does not submit the App Store draft for public review.
