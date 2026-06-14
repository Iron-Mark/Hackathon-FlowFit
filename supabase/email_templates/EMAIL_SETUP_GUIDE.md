# FlowFit Email Template Setup Guide

## 📧 Email Verification Configuration

### Step 1: Configure Site URL in Supabase

Based on your screenshot, you need to set the **Site URL** in Supabase Dashboard:

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to your app's URL:
   - **Development**: `http://localhost:3000` (or your dev port)
   - **Production**: the HTTPS origin configured as `FLOWFIT_PUBLIC_WEB_BASE_URL`

### Step 2: Add Redirect URLs

Add these redirect URLs to the **Redirect URLs** section:

**For Development:**
```
http://localhost:3000
http://localhost:3000/auth/callback
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
```

**For Production:**
```
https://flowfit.your-owned-domain.com
https://flowfit.your-owned-domain.com/auth/callback
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
```

**For Mobile Deep Linking:**
```
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
```

### Step 3: Configure Email Templates

1. Go to **Authentication** → **Email Templates** in Supabase Dashboard
2. Select **Confirm signup** template
3. Update the following:

#### Subject Line:
```
Confirm Your FlowFit Signup ⚡
```

#### Email Body (HTML):
Copy the content from `confirm_signup.html` file in this directory.

### Step 4: Email Template Variables

Supabase provides these template variables:

- `{{ .ConfirmationURL }}` - The verification link
- `{{ .Token }}` - The verification token
- `{{ .TokenHash }}` - Hashed token
- `{{ .SiteURL }}` - Your configured site URL
- `{{ .Email }}` - User's email address

### Step 5: Test Email Flow

1. Create a test account in your app
2. Check your email inbox (and spam folder)
3. Click the verification link
4. Verify the app redirects correctly

### Step 6: Mobile Deep Link Configuration

For Flutter mobile app, configure deep linking:

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="flowfit" android:host="auth" />
    <data android:scheme="flowfit" android:host="email-verification" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>flowfit</string>
        </array>
    </dict>
</array>
```

### Step 7: Handle Deep Links in Flutter

Update your `main.dart` or auth service to handle deep links:

```dart
import 'package:uni_links/uni_links.dart';

// Listen for deep links
StreamSubscription? _linkSubscription;

void initDeepLinks() {
  _linkSubscription = linkStream.listen((String? link) {
    if (link != null && link.contains('email-verification')) {
      // Handle email verification callback
      Navigator.pushReplacementNamed(context, '/survey_intro');
    }
  });
}
```

## 🎨 Email Template Customization

### Brand Colors:
- Primary Blue: `#4A90E2`
- Secondary Blue: `#357ABD`
- Background: `#f2f7ff`

### Emojis Used:
- ⚡ - FlowFit logo
- 📧 - Email icon
- ✓ - Checkmark
- 🔒 - Security
- 👋 - Welcome

## 🔧 Troubleshooting

### Email not received?
1. Check spam/junk folder
2. Verify SMTP settings in Supabase
3. Check email template is enabled
4. Verify Site URL is correct

### Link not working?
1. Verify redirect URLs are configured
2. Check deep link configuration
3. Test with browser first, then mobile

### Auto-verification not working?
1. The app checks every 5 seconds automatically
2. User can also click "I've Verified My Email" button
3. Ensure `emailConfirmedAt` field is being checked

## 📱 Production Checklist

- [ ] Site URL configured correctly
- [ ] All redirect URLs added
- [ ] Email template updated with custom HTML
- [ ] Subject line updated
- [ ] Deep links configured for Android
- [ ] Deep links configured for iOS
- [ ] Test email flow end-to-end
- [ ] Verify auto-check works (5 second interval)
- [ ] Test resend email functionality
- [ ] Verify navigation to survey after confirmation

## 🚀 Current Flow

1. User signs up → `signup_screen.dart`
2. Account created → Navigate to `email_verification_screen.dart`
3. Email sent with verification link
4. Screen auto-checks every 5 seconds for verification
5. User clicks link in email → Email verified in Supabase
6. Auto-check detects verification → Navigate to `survey_intro_screen.dart`
7. User completes survey → Navigate to dashboard

## 📝 Notes

- The verification screen has a 60-second cooldown for resend
- Auto-check runs every 5 seconds in the background
- User can manually check by clicking the button
- Skip button available for testing (remove in production)
