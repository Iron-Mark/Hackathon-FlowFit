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
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
```

### 3. Email Template

Go to **Authentication** → **Email Templates** → **Confirm signup**

**Subject:**
```
Confirm Your FlowFit Signup ⚡
```

**Body:**
Copy and paste the content from `confirm_signup.html` file.

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
https://flowfit.your-owned-domain.com
```

And add production redirect URLs:
```
https://flowfit.your-owned-domain.com
https://flowfit.your-owned-domain.com/auth/callback
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
```

## 📱 Mobile Deep Links

For mobile app, configure deep links in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

See `EMAIL_SETUP_GUIDE.md` for detailed instructions.
