# spec: Facebook Login Resolution

**Date**: 2026-03-15
**Goal**: Resolve "Invalid OAuth" and connection errors in Facebook Login for ChargeTN Android app.

## Current State Analysis
- **Supabase**: Configured and Enabled. App ID matches, Secret is present.
- **Facebook Dashboard**: Package name and Redirect URI are correct.
- **Project Code**: Manifest and Logic are correct.
- **Critical Failure**: Key Hash in Facebook Dashboard (`o1W/...`) does not match local dev hash (`i0ro...`).

## Technical Design
The resolution focuses on synchronizing the security identities between the local Android build and the Facebook Developer Portal.

### 1. Key Hash Synchronization
We must update the Facebook App settings to recognize the current development environment.
- **Local Hash**: `i0rofRr5c2OuXHDS+x3yobUSKiI=` (Derived from `~/.android/debug.keystore`)
- **Action**: Add this hash to the 'Key Hashes' field in Settings -> Basic -> Android.

### 2. App Status Alignment
- **Current**: Development Mode (Only Admins/Testers can log in).
- **Proposed**: Keep in Development Mode for testing, then switch to **Live** for public release.

### 3. URL Scheme Verification
- Ensure the custom scheme `io.supabase.facebookauth` is consistently handled by Supabase and the Android Manifest. (Currently verified as correct).

## Implementation Steps
1. **Manual Portal Update**: User updates the Key Hash in the Facebook Developer Portal.
2. **Connectivity Test**: Run the app and trigger `_signInWithFacebook`.
3. **Verification**: Confirm the browser redirects back to the app and Supabase session is established.

## Success Criteria
- Clicking "Continuer avec Facebook" opens the Facebook auth flow.
- After login, the browser closes and the app navigates to `/home`.
- `SupabaseConfig.client.auth.currentUser` is populated.
