# Supabase Dashboard Configuration for FlowFit

Quick reference for configuring your Supabase project for mobile deep linking.

## 1. URL Configuration

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/url-configuration

### Site URL
Set this to your primary deep link:
```
com.oldstlabs.flowfit://auth-callback
```

### Redirect URLs
Add these URLs (one per line):
```
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
http://localhost:3000/**
```

**Note**: The `**` wildcard allows any path under localhost for web testing.

## 2. Email Templates

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/templates

### Confirm Signup Template

Update the confirmation link to use the redirect URL:

**Subject**: `Confirm Your FlowFit Account`

**Body (HTML)**:
```html
<h2>Welcome to FlowFit!</h2>

<p>Thanks for signing up. Please confirm your email address by clicking the link below:</p>

<p>
  <a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #2563EB; color: white; text-decoration: none; border-radius: 6px;">
    Confirm Email Address
  </a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .ConfirmationURL }}</p>

<p>This link will expire in 24 hours.</p>

<p>If you didn't create an account with FlowFit, you can safely ignore this email.</p>

<p>Thanks,<br>The FlowFit Team</p>
```

**Body (Plain Text)**:
```
Welcome to FlowFit!

Thanks for signing up. Please confirm your email address by clicking the link below:

{{ .ConfirmationURL }}

This link will expire in 24 hours.

If you didn't create an account with FlowFit, you can safely ignore this email.

Thanks,
The FlowFit Team
```

### Available Template Variables

- `{{ .ConfirmationURL }}` - Auto-generated URL with token (uses Site URL or redirectTo)
- `{{ .Token }}` - The verification token
- `{{ .TokenHash }}` - Hashed version of the token
- `{{ .SiteURL }}` - Your configured Site URL
- `{{ .RedirectTo }}` - The redirectTo URL if specified in code
- `{{ .Email }}` - User's email address

## 3. Auth Settings

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/providers

### Email Auth Settings

- ✅ **Enable Email Provider**: ON
- ✅ **Confirm Email**: ON (recommended for production)
- ✅ **Secure Email Change**: ON
- ⏱️ **Email Confirmation Expiry**: 86400 seconds (24 hours)

### PKCE Flow (Mobile Security)

PKCE is automatically enabled when you use `AuthFlowType.pkce` in your Flutter code. This provides additional security for mobile apps.

## 4. Testing Configuration

### For Development

While testing, keep email confirmation enabled and use the maintained-fork
redirect URLs so deep-link verification is exercised.

1. **Add Test Redirect URLs**
   ```
   com.oldstlabs.flowfit.dev://auth-callback
   http://localhost:3000/**
   ```

3. **Use Test Email Services**
   - Consider using [Mailtrap](https://mailtrap.io/) or similar for testing
   - Or use your real email for testing

### For Production

1. **Enable Email Confirmation**: ON
2. **Remove development redirect URLs**
3. **Update Site URL** to production deep link
4. **Test with real email addresses**
5. **Monitor Auth logs** for issues

## 5. Monitoring & Debugging

### View Auth Logs

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/logs/explorer

Filter for auth events:
```sql
SELECT * FROM auth.audit_log_entries 
ORDER BY created_at DESC 
LIMIT 100;
```

### Common Issues

**Issue**: Email not sending
- Check SMTP settings (if using custom SMTP)
- Verify email templates are saved
- Check spam folder

**Issue**: Deep link not working
- Verify redirect URLs match exactly
- Check Android manifest configuration
- Test with ADB command

**Issue**: Token expired
- Default expiry is 24 hours
- User needs to request new verification email

## 6. Security Checklist

Before going live:

- [ ] Email confirmation is enabled
- [ ] PKCE flow is configured in app
- [ ] Production redirect URLs are set
- [ ] Development URLs are removed
- [ ] Email templates are professional
- [ ] Rate limiting is configured
- [ ] Auth logs are monitored

## 7. Rate Limiting

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/rate-limits

Recommended settings:
- **Email sends per hour**: 4 (prevents spam)
- **SMS sends per hour**: 4
- **Sign-ups per hour**: 10 (adjust based on your needs)

## 8. Custom SMTP (Optional)

For production, consider using a custom SMTP provider for better deliverability:

**Dashboard URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/settings/auth

Recommended providers:
- SendGrid
- AWS SES
- Mailgun
- Postmark

## Quick Links

- [Auth URL Config](https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/url-configuration)
- [Email Templates](https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/templates)
- [Auth Settings](https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/providers)
- [Auth Logs](https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/logs/explorer)
- [Rate Limits](https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/rate-limits)
