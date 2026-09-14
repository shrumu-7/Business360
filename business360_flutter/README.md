# Business360 2.0 — Flutter Migration

Business360 2.0 is the cross-platform migration of the existing Business360 business-management app to **Flutter + Dart**.

## Target platforms
- Android
- iOS

## Migration approach
The existing Android/WebView implementation remains intact while the Flutter version is built feature-by-feature. This avoids losing the current business logic during migration.

## Foundation currently added
- Flutter application entry point
- Material 3 UI
- Light/dark theme foundation
- Persistent theme preference
- Responsive navigation structure
- Dashboard foundation
- Sales/POS, Products & Stock, Customers and Reports module placeholders

## Planned modules
Dashboard, Sales/POS, Products, Stock, Purchases, Customers, Suppliers, Accounts, Expenses, Returns, Reports, Backup/Restore, shop branding and app-wide themes.

The Flutter app is intentionally not presented as feature-complete yet; existing Business360 functionality will be migrated incrementally.
