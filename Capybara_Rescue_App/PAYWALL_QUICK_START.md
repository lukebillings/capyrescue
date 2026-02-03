# 🚀 Paywall Quick Start Checklist

Use this checklist to get your paywall up and running quickly.

---

## ☑️ Pre-Launch Checklist

### 1. App Store Connect Setup (30 minutes)

- [ ] Log into [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Go to your app → Features → Subscriptions
- [ ] Create subscription group: "Capybara Pro"
- [ ] Create annual product:
  - [ ] Product ID: `YOUR_BUNDLE_ID.pro.annual`
  - [ ] Price: £29.99/year
  - [ ] Name: "Pro (Annual)"
  - [ ] Set to "Ready to Submit"
- [ ] Create monthly product:
  - [ ] Product ID: `YOUR_BUNDLE_ID.pro.monthly`
  - [ ] Price: £3.99/month
  - [ ] Name: "Pro (Monthly)"
  - [ ] Set to "Ready to Submit"
- [ ] (Optional) Add free trial period to subscriptions
- [ ] Save all changes

### 2. Code Configuration (5 minutes)

- [ ] Open `Managers/SubscriptionManager.swift`
- [ ] Update line 11 with your annual product ID
- [ ] Update line 12 with your monthly product ID
- [ ] Open `Views/PaywallView.swift`
- [ ] Update Terms URL (around line 118)
- [ ] Update Privacy URL (around line 125)

### 3. Xcode Setup (5 minutes)

- [ ] Open Xcode
- [ ] Select your project → Target
- [ ] Go to "Signing & Capabilities" tab
- [ ] Click "+ Capability"
- [ ] Add "In-App Purchase"
- [ ] Verify "iCloud" capability exists (should already be there)
- [ ] Build the project (⌘B) to verify no errors

### 4. Sandbox Testing Setup (10 minutes)

- [ ] In App Store Connect → Users and Access
- [ ] Click "Sandbox Testers"
- [ ] Click "+" to create tester
- [ ] Create test account:
  - [ ] Email: `test.capybara@example.com` (must be unique)
  - [ ] Password: Something secure
  - [ ] Region: United Kingdom
- [ ] Save tester account credentials

### 5. Device Testing (15 minutes)

- [ ] On your iOS device, go to Settings → App Store
- [ ] Sign out of your regular Apple ID
- [ ] In Xcode, select your device
- [ ] Build and run the app (⌘R)
- [ ] When app launches, you should see the paywall
- [ ] Tap "Get Started" on annual plan
- [ ] Sign in with sandbox tester when prompted
- [ ] Complete purchase (won't charge real money)
- [ ] Verify you receive 5,000 coins
- [ ] Close and reopen app
- [ ] Verify paywall doesn't show again
- [ ] Delete app, reinstall, tap "Restore Purchases"
- [ ] Verify subscription restored

---

## 🎯 Must-Do Items Before Submit

- [ ] Terms of Service page created and live
- [ ] Privacy Policy page created and live
- [ ] Both URLs updated in code
- [ ] Tested annual subscription purchase
- [ ] Tested monthly subscription purchase
- [ ] Tested free tier selection
- [ ] Tested restore purchases
- [ ] Tested on multiple devices
- [ ] Verified banner ads hide for Pro users
- [ ] Verified banner ads show for Free users
- [ ] Verified iCloud sync works
- [ ] Screenshots taken for App Store
- [ ] Subscription description written for App Store

---

## 📝 App Store Review Preparation

Apple will ask these questions about your subscriptions:

### Required Info:

**Q: What do users get with the subscription?**
A: "Pro subscribers receive 5,000 coins immediately (2,000 for monthly), an additional 5,000 coins every month (2,000 for monthly), complete removal of banner advertisements, and access to exclusive Pro-only accessories and items."

**Q: Where can users see what they're paying for?**
A: "The paywall screen clearly lists all benefits before purchase. Users must actively tap 'Get Started' to initiate purchase."

**Q: Where are your Terms and Privacy Policy?**
A: "Terms of Service: [YOUR URL] / Privacy Policy: [YOUR URL] - Both are linked at the bottom of the paywall screen."

**Q: Can users restore purchases?**
A: "Yes, there is a 'Restore Purchases' button on the paywall screen and in the app settings."

**Q: Where can users manage/cancel subscriptions?**
A: "Through iOS Settings → [User's Name] → Subscriptions, per Apple's standard subscription management."

---

## 🧪 Testing Scenarios

Test all these scenarios before submitting:

### New User Flow

- [ ] Install app fresh
- [ ] See paywall immediately
- [ ] Choose annual → Get 5,000 coins
- [ ] Banner ads hidden
- [ ] Can access all content

### Returning User Flow

- [ ] User with active subscription
- [ ] Reopen app
- [ ] No paywall shown
- [ ] Subscription benefits active
- [ ] Restore purchases works

### Free User Flow

- [ ] Choose "Continue with Free"
- [ ] Get 500 coins
- [ ] Banner ads visible
- [ ] Can still play game
- [ ] Can earn more through achievements

### Subscription Expiry (Sandbox Only)

- [ ] Subscribe in sandbox
- [ ] Wait for expiry (6 renewals in sandbox)
- [ ] Verify ads return
- [ ] Verify exclusive items locked

### Edge Cases

- [ ] No internet connection
- [ ] Payment method declined
- [ ] User cancels during purchase
- [ ] Multiple devices, same account
- [ ] Switch from monthly to annual

---

## 🔧 Common Issues & Fixes

### "Product not found"

**Fix**: Wait 24 hours after creating products in App Store Connect

### "Cannot connect to iTunes Store"

**Fix**: Make sure sandbox tester is signed in on device

### Paywall shows every time

**Fix**: Check iCloud capability is enabled and working

### Restore purchases doesn't work

**Fix**: Sandbox purchases expire after 6 renewals - create new sandbox tester

### Price shows as £0.00

**Fix**: Products not loaded yet - wait a few seconds and check console logs

---

## 📊 Post-Launch Monitoring

Track these metrics:

### Week 1

- [ ] Total app downloads
- [ ] Paywall view count
- [ ] Annual subscription count
- [ ] Monthly subscription count
- [ ] Free tier count
- [ ] Calculate conversion rate: (Annual + Monthly) / Total Views
- [ ] Calculate annual preference: Annual / (Annual + Monthly)

### Week 2-4

- [ ] Track same metrics
- [ ] Monitor subscription renewals
- [ ] Check for cancellations
- [ ] Read user reviews for feedback
- [ ] Adjust pricing if needed

### Ongoing

- [ ] Monthly Revenue Report (in App Store Connect)
- [ ] Subscription renewal rate
- [ ] Upgrade from monthly to annual
- [ ] Churn rate (cancellations)

---

## 🎨 Optional Enhancements

After launch, consider adding:

- [ ] Limited-time discount for annual plan
- [ ] Referral program for Pro users
- [ ] Gifting subscriptions
- [ ] Family sharing
- [ ] Pro-only capybara skins
- [ ] Pro-only game modes
- [ ] Monthly Pro-only item drops
- [ ] Pro member badge/status

---

## 📱 Need Help?

### Useful Resources:

- [Apple Subscription Documentation](https://developer.apple.com/app-store/subscriptions/)
- [StoreKit Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Console Commands:

```bash
# View system logs for StoreKit
log show --predicate 'subsystem contains "storekit"' --info --last 5m

# Check subscription status
defaults read com.apple.itunesstored
```

---

## ✅ Final Check

Before submitting to App Store:

- [ ] All checkboxes above completed
- [ ] App tested on real device (not just simulator)
- [ ] Sandbox testing complete
- [ ] Legal pages live and linked
- [ ] Screenshots show paywall
- [ ] App description mentions subscriptions
- [ ] Pricing is correct
- [ ] No crashes or errors
- [ ] Paywall looks good on all device sizes (iPhone SE to Pro Max)

---

**Ready to launch?** You've got this! 🚀

Your paywall is built with industry best practices and optimized for maximum annual subscription conversions. Good luck!

---

**Estimated Total Setup Time**: 1-2 hours
**Difficulty Level**: Beginner-Friendly
**Cost**: Free (except Apple Developer account)

Remember: The code is already done and working. You just need to configure the App Store Connect products and update a few IDs. That's it! 🎉
