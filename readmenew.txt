RapidPatch — Global Windows Emergency Patching Platform

Status: Initial requirements and architecture draft (18 November 2026)
Purpose: Rapid, mandatory deployment of emergency Windows OS and application security fixes using existing global DFS/CIFS infrastructure, independently of SCCM’s normal deployment latency.
Intended audience: Windows engineering, application packaging, endpoint security, infrastructure, operations and Splunk teams.

This is a design proposal, not a production-validated security solution. No service running as SYSTEM can be guaranteed “unhackable”; the architecture must be threat-modelled, security-reviewed and penetration-tested before rollout.

1. Objectives
Run a small, reliable Windows endpoint service as Local System.
Poll an approved enterprise DFS namespace for a deployment activation manifest, default every 30 minutes, adjustable for emergencies.
Use existing four-region global CIFS/DFS distribution, avoiding a new application deployment platform.
Deploy patch payloads and manifest through the existing global publication workflow; allow approximately 45 minutes for regional filer replication before deployment activation.
Support OS patches, application patches, and multiple installer formats.
Enforce six deployment waves (0–5) using an existing machine-level OSA system environment variable (exact production variable name to confirm).
Check applicability, installed state, disk space, cache package locally where possible, execute verified installers and verify remediation.
Give logged-on users a mandatory, non-cancellable 10-minute warning, with the exact instruction: “Please save your work and close your apps.”
Make reboot behaviour explicit; support a separate reboot warning/countdown.
Record success/failure and intermediate states in Windows Event Viewer, collected by existing Splunk Universal Forwarder agents.
Prevent the patching service from becoming a general-purpose SYSTEM-level code execution vector.
2. Global Architecture

The organisation has global DFS infrastructure in EMEA, APAC, NA East, and NA West. The existing patch publication engine deploys the approved payload and deployment metadata to the four regional global CIFS shares. Each share is served by regional CIFS filers and replication is expected to take approximately 45 minutes. Endpoints read through their approved regional DFS paths and install after publication is verified and their wave is enabled.

Security / Packaging Team

Patch Validation and Signing

Global Publication Workflow

EMEA CIFS Share

APAC CIFS Share

NA East CIFS Share

NA West CIFS Share

EMEA CIFS Filers

APAC CIFS Filers

NA East CIFS Filers

NA West CIFS Filers

EMEA DFS Namespace

APAC DFS Namespace

NA East DFS Namespace

NA West DFS Namespace

Regional Windows Endpoints

Regional Windows Endpoints

Regional Windows Endpoints

Regional Windows Endpoints

Windows Event Logs

Existing Splunk Forwarders / Splunk

Publication safety gate: Do not assume that waiting exactly 45 minutes proves the package has replicated everywhere. Publish payload files to a unique versioned path first; verify hashes and file completeness on each required regional filer; publish or activate a signed, immutable, final ready manifest only once readiness is verified. If publication is not atomic across DFS referrals or regions, endpoints must fail closed until the whole package and signature are locally visible and valid. An activation time must not precede regional readiness. The publication controller should record region-by-region readiness; endpoints still validate independently.

2.1 Deployment sequence
Security/package owner approves the patch, installation method, applicability and detection rules.
A trusted publisher produces versioned payload files and a signed manifest containing payload hashes.
Existing publishing workflow copies them into each of four regional CIFS distribution locations.
CIFS infrastructure replicates into backing filers (expected ~45 minutes, subject to measurement).
Publishing workflow confirms each required region has the complete files; only then activates a signed deployment flag / ready manifest.
Endpoint service polls its regional approved DFS namespace, validates authenticity and reads its machine OSA wave value.
When eligible: assess applicability and disk space; cache content to restricted local storage if configured; verify hash/signatures; warn user; install.
Independently verify installed version, KB, registry or package state; handle reboot according to policy.
Emit structured Event Viewer records for each stage; existing Splunk agent collects them.
2.2 Timing expectation

Total time to install ≠ 30 minutes. A rough earliest-common-path estimate includes regional replication (~45 minutes), endpoint polling (0–30 minutes after activation), wave scheduling, package transfer, 10-minute mandatory warning, installer duration and any reboot. Emergency polling may be reduced to 1–5 minutes with capacity testing, but propagation must finish before activation. Avoid a thundering herd by using deterministic jitter and wave limits.

3. Endpoint Windows Service
Run as Local System only where required for patching; isolate privilege-sensitive execution from parsing, UI, cache and network concerns where feasible.
Auto-start, restart on failure, persist transaction state and recover across reboots.
Poll configured, fixed enterprise DFS location, default 30 minutes, with bounded random jitter; network outages must not cause unsafe fallback.
Treat all network metadata, manifests, and payloads as untrusted until authenticated.
Read the current machine-level wave setting directly at each evaluation, not only from the service process environment at boot.
Maintain a local per-deployment state record to avoid repeated installs; use global execution mutex / lock to avoid concurrent patch operations.
Store files under a tightly ACL-protected path such as C:\ProgramData\RapidPatch\Cache; protect configuration and service binary.
Reject deployments that are expired, withdrawn, unsigned, rollbacked to older revision, malformed, ineligible, or missing required files.
Handle network disconnects, interrupted copies, disk pressure, long-running installers, unexpected exit codes, cancellation by authorized publisher and pending reboot.
4. Manifest and Deployment Flag

The JSON is declarative metadata, not an arbitrary script runner. All fields require schema and semantic validation, bounded lengths and controlled values. Manifest/signature and payloads are versioned and immutable after publication.

Required / recommended fields:

Field	Purpose
schemaVersion	Schema compatibility and migration
deploymentId, revision	Unique immutable patch identity; anti-replay
enabled, state, createdUtc, expiresUtc	Deployment activation and validity
patchType	OS or Application
product, targetVersion, kbIds	Target product and versions / KBs
installType	MSI, EXE, BAT, PowerShell, Cloudpaging, MSU, CBS, other approved adapter
payload.relativePath, payload.sha256, payload.sizeBytes	Approved payload locator and integrity
installation.adapter, installation.arguments	Approved installer adapter and tightly constrained parameters
installation.timeoutSeconds, successCodes	Runtime behaviour and exit-code classification
detection	Prerequisite checks, applicability and post-install remediation validation
cache.required, cache.minFreeSpaceMB	Cache / disk policy
waves.activationUtc	Activation times for waves 0–5
notification	Mandatory warning, countdown, app-close instruction
reboot	Required policy, countdown, deadline
security.signerId, signature	Authenticated publisher and manifest signature (exact format TBD)

Example — illustrative only (not signed or production-ready):

{
  "schemaVersion": 1,
  "deploymentId": "SEC-2026-001",
  "revision": 1,
  "enabled": true,
  "state": "ready",
  "createdUtc": "2026-11-18T05:00:00Z",
  "expiresUtc": "2026-12-18T05:00:00Z",
  "patchType": "Application",
  "product": "Example Application",
  "targetVersion": "5.2.1",
  "installType": "MSI",
  "payload": {
    "relativePath": "SEC-2026-001/update.msi",
    "sha256": "REPLACE_WITH_VERIFIED_SHA256",
    "sizeBytes": 12345678
  },
  "installation": {
    "adapter": "MSI",
    "arguments": ["/qn", "/norestart"],
    "timeoutSeconds": 1800,
    "successCodes": [0, 3010, 1641]
  },
  "detection": {
    "type": "MSIProductVersion",
    "productCode": "REPLACE_WITH_PRODUCT_CODE",
    "minVersion": "5.2.1"
  },
  "cache": {"required": true, "minFreeSpaceMB": 2048},
  "waves": {
    "0": "2026-11-18T08:00:00Z",
    "1": "2026-11-18T09:00:00Z",
    "2": "2026-11-18T10:00:00Z",
    "3": "2026-11-18T11:00:00Z",
    "4": "2026-11-18T12:00:00Z",
    "5": "2026-11-18T13:00:00Z"
  },
  "notification": {
    "enabled": true,
    "preInstallCountdownSeconds": 600,
    "mandatory": true,
    "allowCancel": false,
    "allowPostpone": false,
    "message": "Please save your work and close your apps."
  },
  "reboot": {
    "rebootRequired": true,
    "policy": "NotifyAndEnforce",
    "countdownSeconds": 600,
    "deadlineUtc": "2026-11-19T12:00:00Z"
  },
  "security": {
    "signerId": "REPLACE_WITH_APPROVED_PUBLISHER",
    "signature": "REPLACE_WITH_REAL_DETACHED_OR_ENVELOPED_SIGNATURE"
  }
}
 

Important implementation choice: Sign a canonicalized representation or an exact immutable byte sequence with a documented signature format. Do not sign JSON and then reinterpret it inconsistently. Maintain strict key-management, signer rotation and revocation procedures. A bare SHA-256 value does not authenticate its source.

5. Wave Targeting
Six production wave values: 0, 1, 2, 3, 4, 5.
Read from an existing machine-scoped OSA environment variable (name to confirm with the estate team; OSA_PATCH_WAVE is only a provisional example).
Read afresh before each deployment eligibility decision, using an appropriate machine-level source (not a stale inherited service environment).
Missing/out-of-range values → no action; configuration error event.
Signed manifest provides activation time for each wave. The endpoint only installs after its wave opens.
Machines offline during their wave install at next successful check-in if the manifest remains active and applicable.
Optionally include device group restrictions in addition to wave; user-editable wave variables alone are not a strong authorization control.
Wave progress and abort decisions are centrally governed by authorized deployment publishers.
6. Supported Installation Types

Design an installer-adapter interface with typed, restricted configuration. Initially include:

MSI: Windows Installer / msiexec with allowed arguments and MSI-specific exit-code handling.
EXE: allowlisted, authenticode-verified vendor installer with tested silent flags.
BAT / CMD: only pre-reviewed signed-package scripts, executed through a tightly controlled adapter; no arbitrary command string from unsigned JSON.
PowerShell: approved scripts with signature enforcement and restrictive execution policy / application-control controls; do not assume PowerShell -ExecutionPolicy is a security boundary.
Cloudpaging: approved adapter using supported enterprise client/tool interfaces, package/version detection and Cloudpaging-specific outcomes.
MSU / Windows servicing: supported Windows servicing APIs / WUSA / DISM where appropriate, with servicing-stack and reboot handling.
Future adapters permitted only after a formal security review.

Capture the installation command line / arguments in the manifest, but never permit unconstrained cmd.exe /c, shell metacharacters, arbitrary absolute paths or user-controlled executable locations. All payload paths must be relative to an allowlisted, authenticated distribution root, and process launching should use explicit executable and argument boundaries.

For each adapter define isApplicable, isInstalled, stage, install, verify, rebootState, errorClassification and cleanup operations. Exit code zero alone is insufficient evidence that a vulnerability is fixed.

7. Local Cache / Disk Checks
Verify a package is eligible and not already installed.
Determine required bytes for archive, extracted content, logs and installation headroom.
Check local filesystem capacity; log actual free bytes and required bytes.
Download to a restricted temporary file with no executable ACL for ordinary users.
Validate complete size, cryptographic digest, manifest authentication and installer publisher/signing requirements; move atomically into a versioned cache.
Revalidate immediately before process execution; avoid time-of-check/time-of-use race conditions.
Install from the controlled local cache; retain or clean according to a defined policy.
Log cache start, cache success, cache bypass, insufficient space, integrity failure and copy failure.

If caching is impossible, default to fail safely, unless a separately approved manifest policy permits streaming from a validated approved source without creating a risky direct-execution path.

8. Mandatory User Notification / Countdown

Use a separate per-user-session C/C++ notification process (Session 0 Windows services cannot show interactive desktop UI directly); communication with privileged service uses authenticated, ACL-restricted IPC.

Exact message: “Please save your work and close your apps.”

Notify 10 minutes / 600 seconds before an eligible installation, with a continuously updated countdown.
Display application/product name, what will happen, and whether reboot will follow.
No Cancel or Postpone actions for the user. Acknowledge/minimise is acceptable but does not stop the timer.
On expiry, begin the approved installation workflow; capture notification shown/acknowledged/countdown expiration events.
Check for affected processes. If still open, use a documented enterprise close policy including a final warning and controlled graceful shutdown attempt; forced closure may cause unsaved work loss and requires explicit administrative approval and legal/operational review.
Define behaviour for multiple sessions, locked screens, users who sign out, disconnected RDP sessions and headless servers. Headless systems should not block permanently waiting for a UI.
End users cannot control service deployment state; only authenticated administrative withdrawal/pause can stop a pending job.
9. Reboots
Manifest field: reboot.rebootRequired: true/false.
Distinguish policy-required reboot from installer or OS-detected pending reboot.
MSI exit 3010 = successful install, reboot required; 1641 = successful install and reboot initiated. Other adapters have their own return codes.
Honor /norestart or equivalent when possible; prevent unexpected immediate restarts.
For mandatory reboot: show a separate countdown (default example: 10 minutes), policy/deadline, logged-in sessions and reboot events; do not confuse installation countdown with reboot countdown.
After reboot, service resumes and verifies remediation and records completion. Avoid endless reboot loops.
10. Windows Event Viewer / Splunk

Register a structured Event Log provider/channel (recommended: Applications and Services Logs → RapidPatch → Operational) that the existing Splunk Universal Forwarder can collect. Critical security rejections can additionally use an Audit channel where appropriate.

Common event fields: timestamp UTC, hostname, deployment ID/revision, patch type, product/KB, target version, wave, region/DFS source identifier, cache attempted/used, required and available disk bytes, stage, duration, result, installer exit code, Windows error / HRESULT, reboot state, sanitized message and correlation ID. Avoid writing secrets or sensitive command-line values.

ID	Severity	Event
1000	Info	Manifest discovered and authenticated
1001	Info	Wave eligibility satisfied
1002	Info	Target already remediated; skipped
1003	Warning	Missing or invalid OSA wave
1004	Info	Device outside deployment wave / scheduled for later
1050	Info	Pre-install countdown displayed
1051	Info	Pre-install countdown expired
1100	Info	Cache transfer started
1101	Info	Cache successful
1102	Error	Insufficient disk space
1103	Error	Cache/network transfer failed
1104	Error	Package integrity or signature failure
1200	Info	Installation started
1201	Info	Installer completed successfully
1202	Error	Installer execution failed or timed out
1203	Warning	Reboot required or pending
1250	Info	Post-install verification passed
1251	Error	Post-install verification failed
1300	Info	Deployment complete / remediated
1301	Error	Deployment failed
1350	Info	Reboot scheduled / countdown
1351	Info	Endpoint resumed after reboot
1400	Error	Manifest invalid, unsigned, expired or unauthorised
1401	Error	Unapproved path/referral or publisher detected
1500	Info	Service heartbeat / status (low frequency)

Splunk dashboards should report per-wave compliance, terminal failure reasons, caching/disk incidents, pending reboots, no-check-in hosts, and deployment/region rollout progress. Aggregate device inventory from authoritative endpoint sources to distinguish machines with no events from successful skip decisions.

11. Security Architecture — Mandatory

Threat model: An attacker may compromise a DFS share, corrupt a manifest, alter a network referral, replace a cached file, replay an older signed manifest, interfere with the notification process, or exploit the privileged agent. The goal is to make these actions insufficient to achieve arbitrary SYSTEM execution, and to detect/recover from attempts.

Required protections:

Publisher signatures: Manifest signed by approved private key controlled outside distribution shares; endpoint has pinned trusted verification key(s). Implement key rotation/revocation and signer authorization.
Payload integrity: Hashes included in the signed manifest. Independently enforce Authenticode/publisher checks for applicable binaries, with a documented policy for scripts and legacy payloads.
DFS path allowlist: Explicit namespaced root(s), server/share/referral policy and vetted canonicalized paths; reject path traversal, UNC redirection, junctions/symlinks, alternate data streams and local file escapes. Validate resolved source and destination rather than trusting the string alone.
Least privilege: Parser and notification components unprivileged; privileged install broker accepts only authenticated, validated requests. Lock down service control permissions, binaries, directories, registry, IPC ACLs and cache.
Execution constraints: Fixed adapter registry, typed arguments, allowlisted binaries/signers, no generic shell interpreter endpoint, explicit working directory and inherited handle policy. Apply Windows Defender Application Control / App Control for Business or AppLocker where estate policy permits.
Anti-replay / emergency stop: Monotonic manifest revision tracking; time/expiry policy; signed halt or revoke manifests, robust against rollback of the share.
Secure copy and TOCTOU: Read to local restricted temp file, validate, atomic rename, revalidate before use; execute only pinned file version.
Logging and detection: Detailed security failure events; log tamper attempts. Logs alone are not a prevention boundary.
Testing: Independent threat model, code review, fuzzing of JSON/path parsers, DLL-search-path hardening, service ACL validation, adversarial tests, signed publishing pipeline verification and external penetration test.
Operational controls: Dual approval for high-risk scripts, segmented publishing rights, secured signing keys, package provenance, signed audit trail and documented incident response.

Important limitation: A hostile local administrator or kernel-level attacker may be able to compromise even a well-designed endpoint. The realistic target is defence in depth, minimal attack surface and enforceable trust boundaries, not “unhackable.”

12. Reliability, Failure, and Rollout Controls
Idempotency: Do not reinstall completed patches; treat a deployment ID/revision as a transaction.
Interrupted replication: Never install incomplete/partially updated regional content.
Offline clients: Catch up when online and eligible, subject to expiry and stop controls.
Global load control: Poll jitter, wave spacing, per-region load limits, cache throttling and SMB capacity planning.
Multiple pending patches: Priority, sequencing, dependencies and mutual exclusion; handle simultaneous reboot requirements.
Retry: Explicit transient vs permanent errors, bounded exponential backoff; no endless failure loops.
Safety: Pending reboot, BitLocker considerations, maintenance windows, critical servers, VDI persistence, application dependencies and business-hours policy require documented fleet rules.
Rollback: Use package-specific uninstall/restore where supported. OS security patches may not be safely reversible.
Emergency pause: Signed administrative stop/withdrawal supersedes previously issued deployment; client verifies status before execution.
Verification: Compare final OS build/KB/application file/product/version to expected remediated state; log post-reboot state.
Health: Separate monitoring for agent crash, version drift, missing heartbeat and log delivery failure.
13. MVP Implementation Plan

Phase 1 — Protocol and secure publication

Agree exact DFS/CIFS paths/referral behaviour, regional replication verification, OSA variable name and signature scheme.
Build signed manifest format, publisher and verify-only client; model partial replication and tampering.

Phase 2 — Endpoint Windows service

Implement polling, eligibility/wave engine, durable state, disk checks, local cache, MSI adapter, installation verification and Windows Event Logs.

Phase 3 — User interaction and reboot

Implement native C/C++ session UI, mandatory 600-second pre-install countdown, app-close checks and independent reboot workflow.

Phase 4 — Installer extensibility

Add EXE, MSU and PowerShell/BAT approved adapters; then Cloudpaging using confirmed supported integration interfaces.

Phase 5 — Global rollout validation

Validate with Wave 0 IT devices, one region initially, then all four regions, Splunk ingestion, failover, DFS referral attacks and load tests.
Acceptance test checklist
 Endpoint with wave 0–5 installs only after its activation UTC and completed regional publication.
 Machine-scoped OSA wave is read reliably without service restart.
 Partial regional filer replication never triggers install.
 Unsigned/tampered manifest cannot execute code.
 Payload hash mismatch / wrong publisher blocks execution and produces Event Log alert.
 DFS redirection or unexpected share source blocks execution.
 Low disk space produces actionable event without partial installation.
 User sees exactly “Please save your work and close your apps.” with live 10-minute countdown.
 User cannot cancel or postpone via UI; authorised signed withdrawal still works.
 Installer success, failure, timeout and reboot-required codes correctly classified.
 Installed-state verification is independent of installer exit code.
 Reboot sequence survives machine restart and correctly logs eventual success/failure.
 Offline/reconnected endpoint retries safely without duplicate installation.
 Splunk receives structured phase, error, wave and region reporting.
 Load tests cover simultaneous global activation and DFS filer capacity.
14. Open Decisions
Exact OSA machine-level wave environment variable name and provisioning/permissions.
Exact four approved global CIFS/DFS namespaces, regional filer referral policy and publication API.
How publication workflow proves replication complete in each region; whether manifest activation is separate from package publication.
Certificates / public-key trust root, signing pipeline, revocation and break-glass control.
Which machines are eligible (persistent desktop, VDI, RDSH, servers), especially user notification and mandatory reboot policies.
Cloudpaging integration method and how installation/version is authoritatively detected.
Whether any patches are allowed to install without local caching.
Forced-close policy for unsaved app data and conflicting processes.
Reboot deadline/deferral policy for critical server and workstation populations; user cancellation of patch installation remains prohibited.
Installer-specific rollback, dependency, supersedence and emergency withdrawal rules.

Summary: RapidPatch is a small, locked-down Windows emergency patch agent that consumes authenticated, globally replicated DFS/CIFS content, gates rollout by six OSA-defined waves, enforces mandatory user warnings and patching, handles reboots, and supplies comprehensive local Event Viewer telemetry to the existing Splunk estate. The signing/validation boundary and per-region replication-readiness gate are essential to safely operating it under SYSTEM.