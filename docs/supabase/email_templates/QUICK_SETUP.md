# Quick Setup for Supabase Email Verification

## 🚀 5-Minute Setup

### 1. Site URL Configuration
In Supabase Dashboard → **Authentication** → **URL Configuration**:

**Site URL:**
```
http://localhost:3000
```
(Change to the HTTPS origin configured as `FLOWFIT_PUBLIC_WEB_BASE_URL` when deploying.)

### 2. Redirect URLs
Add these URLs in the **Redirect URLs** section:

```
http://localhost:3000
http://localhost:3000/auth/callback
com.msiazondev.flowfit://auth-callback
com.msiazondev.flowfit.dev://auth-callback
```

### 3. Email Template

Go to **Authentication** → **Email Templates** → **Confirm signup**

**Subject:**
```
Confirm Your FlowFit Signup ⚡
```

**Body:**
Render dashboard-ready templates after the support inbox has received an
external test email:

```powershell
$env:FLOWFIT_SUPPORT_EMAIL = Read-Host 'Verified support email'
$env:FLOWFIT_SUPPORT_EMAIL_VERIFIED = 'true'
pwsh -NoProfile -File scripts/render_supabase_email_templates.ps1 -SupportEmailVerified
```

Copy and paste the rendered
`build/supabase-email-templates/confirm_signup.html` content into the dashboard
body. Keep `build/supabase-email-templates/confirm_signup.txt` with the release
handoff as a plain-text/archive fallback, and keep the source template
placeholder `REPLACE_WITH_FLOWFIT_SUPPORT_EMAIL` in git. The privacy and
account-deletion links use Supabase's `{{ .SiteURL }}` template variable, so set
Site URL to the correct app/web origin first.

### 4. Test the Flow

1. Run your app
2. Create a new account
3. Check your email
4. Click the verification link
5. App should auto-detect and navigate to survey

## ✅ That's it!

The app will:
- Auto-check verification every 5 seconds
- Show a clean verification screen
- Navigate to survey once verified
- Allow manual resend with 60s cooldown

## 🔧 For Production

Update Site URL to your production domain:
```
<FLOWFIT_PUBLIC_WEB_BASE_URL>
```

And add production redirect URLs:
```
<FLOWFIT_PUBLIC_WEB_BASE_URL>
<FLOWFIT_PUBLIC_WEB_BASE_URL>/auth/callback
com.msiazondev.flowfit://auth-callback
com.msiazondev.flowfit.dev://auth-callback
```

## 📱 Mobile Deep Links

For mobile app, configure deep links in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

See `EMAIL_SETUP_GUIDE.md` for detailed instructions.
