# Mobile Deep Linking Setup for Supabase Auth

This guide explains how to set up mobile deep linking for email verification in your FlowFit Flutter app.

## Overview

Deep linking allows email verification links to open directly in your mobile app instead of a browser. When users click the verification link in their email, the app will open and automatically verify their account.

## 1. Configure Deep Link Scheme

### Choose Your Deep Link URI

For FlowFit, we'll use:
- **Production**: `com.oldstlabs.flowfit://auth-callback`
- **Development**: `com.oldstlabs.flowfit.dev://auth-callback`

## 2. Android Configuration

### Update AndroidManifest.xml

Add an intent filter to your MainActivity to handle deep links:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...>
    
    <!-- Existing intent filter -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Deep Link Intent Filter for Supabase Auth -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Production deep link -->
        <data
            android:scheme="com.oldstlabs.flowfit"
            android:host="auth-callback" />
            
    </intent-filter>
</activity>
```

Use `android/app/src/debug/AndroidManifest.xml` for the development
`com.oldstlabs.flowfit.dev://auth-callback` scheme. Do not package the
development scheme in store release artifacts.

## 3. iOS Configuration (Future)

When you're ready to support iOS, add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.oldstlabs.flowfit</string>
        </array>
    </dict>
</array>
```

## 4. Supabase Dashboard Configuration

### Set Redirect URLs

1. Go to: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/url-configuration
2. Add these URLs to **Redirect URLs**:
   - `com.oldstlabs.flowfit://auth-callback`
   - `com.oldstlabs.flowfit.dev://auth-callback` (for testing)
   - `http://localhost:3000/**` (for web testing)

### Update Site URL

Set **Site URL** to your production deep link:
- `com.oldstlabs.flowfit://auth-callback`

## 5. Update Email Templates

Your email templates need to use the deep link URL. In Supabase Dashboard:

1. Go to: Authentication > Email Templates
2. Update the **Confirm signup** template:

```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your account:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your email</a></p>

<!-- Or use RedirectTo if you set it in code -->
<p><a href="{{ .RedirectTo }}">Confirm your email</a></p>
```

**Important**: The `{{ .ConfirmationURL }}` will automatically use your Site URL or the `redirectTo` parameter from your signup code.

## 6. Flutter Code Implementation

### Update Supabase Initialization

Modify `lib/main.dart` to handle deep links:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseRuntimeConfig.url,
    anonKey: SupabaseRuntimeConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  // Set up deep link listener
  _setupDeepLinkListener();
  
  runApp(const ProviderScope(child: FlowFitPhoneApp()));
}

void _setupDeepLinkListener() {
  // Listen for deep link auth callbacks
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      // User authenticated via deep link
      print('User authenticated: ${session.user.email}');
    }
  });
}
```

### Update Sign Up Code

When signing up, specify the `redirectTo` parameter:

```dart
Future<void> signUp(String email, String password) async {
  final response = await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: 'com.oldstlabs.flowfit://auth-callback',
  );
  
  if (response.user != null) {
    // Navigate to email verification screen
    Navigator.pushNamed(context, '/email_verification', arguments: {
      'email': email,
    });
  }
}
```

### Handle Deep Link in App

Create a deep link handler that processes the auth callback:

```dart
class DeepLinkHandler {
  static Future<void> handleDeepLink(Uri uri) async {
    if (uri.host == 'auth-callback') {
      // Extract token from URI
      final token = uri.queryParameters['token'];
      final type = uri.queryParameters['type'];
      
      if (token != null && type == 'signup') {
        try {
          // Verify the token
          await Supabase.instance.client.auth.verifyOTP(
            token: token,
            type: OtpType.signup,
          );
          
          // Navigate to survey or dashboard
          // This will be handled by auth state listener
        } catch (e) {
          print('Error verifying token: $e');
        }
      }
    }
  }
}
```

## 7. Testing Deep Links

### Test on Android Device

1. Build and install the app:
   ```bash
   flutter run -d <device-id>
   ```

2. Sign up with a real email address

3. Check your email and click the verification link

4. The app should open automatically and verify your account

### Test with ADB (Android Debug Bridge)

You can simulate a deep link without email:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "com.oldstlabs.flowfit://auth-callback?token=test&type=signup" com.oldstlabs.flowfit
```

### Test URL Pattern Matching

Use this tool to test wildcard patterns:
https://www.digitalocean.com/community/tools/glob

## 8. Common Issues & Solutions

### Issue: Deep link doesn't open app

**Solution**: 
- Verify `android:autoVerify="true"` is set
- Check that `android:exported="true"` on MainActivity
- Ensure the scheme matches exactly in both manifest and Supabase config

### Issue: App opens but doesn't verify

**Solution**:
- Check that you're listening to `onAuthStateChange`
- Verify the token is being extracted from the URI correctly
- Check Supabase logs for verification errors

### Issue: Email link opens in browser instead of app

**Solution**:
- Android may need to "learn" the association. Try opening the link multiple times
- Check that the deep link scheme is registered correctly
- For Android 12+, ensure `android:autoVerify="true"` is set

## 9. Production Checklist

Before going to production:

- [ ] Confirm `com.oldstlabs.flowfit` is owned by the selected store accounts
- [ ] Update deep link scheme to match production package
- [ ] Set production Site URL in Supabase Dashboard
- [ ] Remove development deep link schemes
- [ ] Test on multiple Android versions
- [ ] Test with real email addresses
- [ ] Verify email templates use correct URLs
- [ ] Set up iOS deep linking (when ready)

## 10. Security Considerations

- Deep links use PKCE (Proof Key for Code Exchange) flow for security
- Tokens are single-use and expire quickly
- Always validate tokens on the server side (Supabase handles this)
- Never expose sensitive data in deep link URLs

## Resources

- [Supabase Deep Linking Docs](https://supabase.com/docs/guides/auth/auth-deep-linking/auth-deep-linking)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
