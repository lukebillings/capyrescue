# Paywall Setup Guide

## Overview

Your app now has a beautiful, conversion-optimized paywall that displays before the initial screen loads. The paywall is designed to maximize conversions to the annual subscription using proven UX tactics.

## Features Implemented

### 🎯 Conversion Optimization for Annual Plan

1. **Visual Hierarchy**: Annual plan is 5% larger and more prominent
2. **"BEST VALUE" Badge**: Eye-catching gold badge on annual plan
3. **Price Anchoring**: Shows monthly price (£2.49/month) instead of full £29.99
4. **Savings Display**: Calculates and shows % saved vs monthly (e.g., "Save 38%")
5. **Premium Styling**: Gold gradient borders and shadows on annual plan
6. **Featured Design**: Annual plan has enhanced glass morphism effect
7. **Strategic Positioning**: Annual plan appears first (top position)

### 💳 Subscription Tiers

**Pro (Annual) - £29.99/year**

- 5,000 coins to start
- 5,000 extra coins per month
- No banner ads
- Exclusive Pro items
- Displays as "£2.49/month" for better perception

**Pro (Monthly) - £3.99/month**

- 2,000 coins to start
- 2,000 extra coins per month
- No banner ads
- Exclusive Pro items

**Free**

- 500 coins to start
- Banner ads shown
- Can earn more through achievements or coin packs

### 🎨 Design Features

- Matches your existing color scheme (dark gradient background with gold accents)
- Animated background with orbs
- Smooth transitions and haptic feedback
- Clean, modern iOS design
- Can't be dismissed (user must choose a plan)

## Setup Instructions

### 1. Configure App Store Connect

#### Create Subscription Group

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "Features" → "Subscriptions"
4. Create a new subscription group (e.g., "Capybara Pro")

#### Create Subscription Products

**Annual Subscription:**

- Product ID: `com.capybara.pro.annual` (or your bundle ID prefix)
- Duration: 1 Year
- Price: £29.99
- Auto-renewable: Yes

**Monthly Subscription:**

- Product ID: `com.capybara.pro.monthly` (or your bundle ID prefix)
- Duration: 1 Month
- Price: £3.99
- Auto-renewable: Yes

#### Optional: Add Free Trial

If you want to offer a free trial:

1. Edit each subscription
2. Add introductory offer
3. Set trial duration (e.g., 7 days, 1 month)
4. The paywall will auto-detect and display trial info

### 2. Update Product IDs in Code

Open `SubscriptionManager.swift` and update the product IDs:

```swift
// Product IDs - update these with your actual App Store Connect product IDs
static let annualProductId = "YOUR_BUNDLE_ID.pro.annual"
static let monthlyProductId = "YOUR_BUNDLE_ID.pro.monthly"
```

### 3. Update Legal URLs

Open `PaywallView.swift` and update the placeholder URLs (around line 120):

```swift
Button(action: { openURL("https://yourwebsite.com/terms") }) {
    Text("Terms of Service")
}

Button(action: { openURL("https://yourwebsite.com/privacy") }) {
    Text("Privacy Policy")
}
```

**Important**: Apple requires Terms of Service and Privacy Policy URLs for apps with auto-renewable subscriptions. You can:

- Create pages on your website
- Use services like [TermsFeed](https://www.termsfeed.com) or [GetTerms](https://getterms.io)
- Host them on GitHub Pages

### 4. Configure Sandbox Testing

#### Create Sandbox Tester Account

1. In App Store Connect → "Users and Access" → "Sandbox Testers"
2. Create a new sandbox tester with a unique email
3. Use this account to test purchases

#### Test on Device

1. Sign out of your real Apple ID in Settings → App Store
2. Build and run the app
3. When prompted, sign in with your sandbox tester account
4. Test all three paywall options:
   - Annual subscription
   - Monthly subscription
   - Free plan
   - Restore Purchases

**Note**: Subscriptions renew much faster in sandbox:

- 1 week subscription = 3 minutes
- 1 month subscription = 5 minutes
- 1 year subscription = 1 hour

### 5. Add In-App Purchase Capability

In Xcode:

1. Select your project → Target → "Signing & Capabilities"
2. Click "+ Capability"
3. Add "In-App Purchase"
4. Ensure your Apple Developer account is configured

## How the Paywall Works

### Flow

1. **App Launch** → User sees paywall (first time only)
2. **Paywall** → User chooses a plan
3. **Onboarding** → User sets capybara name and enables notifications
4. **Main App** → User plays the game

### Data Storage

- User's subscription tier is stored in `GameState`
- Syncs across devices via iCloud
- Banner ads automatically hidden for Pro users
- Initial coins awarded based on tier selected

### Subscription Validation

- Uses StoreKit 2 for modern subscription handling
- Automatic receipt verification
- Restore purchases available
- Subscription status synced on app launch

## Monthly Coin Rewards

The system is set up to award monthly coins, but you'll need to implement the delivery mechanism. Options:

### Option A: Server-Side (Recommended for Production)

- Set up a server to validate receipts
- Use Apple's Server Notifications to detect renewals
- Award coins when subscription renews

### Option B: Client-Side (Simple)

- Track last coin award date
- Check on app launch if subscription renewed
- Award coins if a month has passed

Add this logic to `GameManager.swift` in the `checkDailyLogin()` method or create a new `checkMonthlySubscriptionRewards()` method.

## Testing Checklist

- [ ] Annual subscription purchase works
- [ ] Monthly subscription purchase works
- [ ] Free plan selection works
- [ ] Correct coins awarded for each tier (5000/2000/500)
- [ ] Banner ads hidden for Pro users
- [ ] Banner ads shown for Free users
- [ ] Restore purchases works
- [ ] Subscription persists after app restart
- [ ] Error messages display correctly
- [ ] Loading states work properly
- [ ] Haptic feedback triggers
- [ ] Terms/Privacy links open correctly

## Exclusive Pro Items

To add Pro-only items/accessories:

1. Open `Models/GameState.swift`
2. Add a `isProOnly: Bool` field to `AccessoryItem`
3. In shop UI, check `gameManager.hasProSubscription()` before allowing purchase
4. Show lock icon or "Pro Only" badge on locked items

Example:

```swift
func purchaseAccessory(_ item: AccessoryItem) -> Bool {
    if item.isProOnly && !hasProSubscription() {
        showToast("This item requires Pro subscription")
        return false
    }
    // ... rest of purchase logic
}
```

## Analytics Recommendations

Consider tracking:

- Paywall view count
- Conversion rate by tier
- Time spent on paywall
- Free → Pro upgrade rate
- Monthly → Annual upgrade rate

Use these metrics to optimize pricing and presentation.

## Troubleshooting

### "Product not found" Error

- Verify product IDs match exactly in App Store Connect and code
- Ensure products are "Ready to Submit" in App Store Connect
- Wait 24 hours after creating products (they need to propagate)
- Check bundle ID matches

### Purchases Not Working

- Verify "In-App Purchase" capability is enabled
- Check sandbox tester account is signed in
- Ensure device has internet connection
- Check Xcode console for detailed error messages

### Restore Purchases Not Working

- Sandbox purchases expire after 6 renewals
- Create a new sandbox tester if needed
- Ensure you're testing with the same Apple ID that made the purchase

### Paywall Shows Every Time

- Check `gameState.hasCompletedPaywall` is being saved
- Verify iCloud sync is working (check iCloud capability)
- Test on a single device first before testing multi-device sync

## Support

If you encounter issues:

1. Check Xcode console for error messages
2. Verify all setup steps completed
3. Test with sandbox account first
4. Check App Store Connect for product status

## Next Steps

1. **Create subscription products** in App Store Connect
2. **Update product IDs** in `SubscriptionManager.swift`
3. **Add legal URLs** in `PaywallView.swift`
4. **Test thoroughly** with sandbox account
5. **Implement monthly coin delivery** (if using server-side)
6. **Add Pro-only items** to the shop
7. **Submit for review** with subscription details

---

**Built with conversion optimization in mind!** 🚀

The annual plan is designed to be the most attractive option using:

- Visual prominence (larger, featured)
- Price psychology (monthly equivalent price)
- Social proof ("BEST VALUE" badge)
- Value emphasis (savings percentage)
- Strategic positioning (top of list)

Good luck with your subscription revenue! 🎉
