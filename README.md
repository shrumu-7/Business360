# Business360

## Smart Business Management App

Business360 is a mobile-first business management application designed to help small businesses manage daily operations from one place. It brings sales, products, inventory, customers, suppliers, dues, expenses, returns, reports, and business settings into a single practical workflow.

> A focused business operations app built for real-world day-to-day management.

## Product Highlights

- Sales and POS workflow
- Product and stock management
- Purchase management
- Customer and supplier records
- Due and account tracking
- Expense management
- Sales and purchase returns
- Business reports and dashboard insights
- Dashboard card arrangement and personalization
- Multiple app themes with persistent settings
- Shop logo and business-name customization
- Backup and restore support
- Cloud-sync capable architecture
- Mobile-first interface for everyday use

## Why This Project Stands Out

Business360 is built around usability rather than a collection of disconnected features. The dashboard gives quick access to important business information, while persistent settings and personalization make the application adaptable to different shops and workflows.

The project also focuses on mobile interaction quality, including touch-friendly navigation, dashboard organization, and reliable local data initialization.

## Theme & Personalization

The application includes an app-wide theme system intended to keep the visual experience consistent across the dashboard, content areas, navigation, and empty/background spaces. Theme selection is stored with application settings so the selected appearance can persist between sessions.

Business identity can also be customized with shop information and branding elements.

## Technology Stack

- Android
- Java
- Gradle
- Android WebView
- HTML5
- CSS3
- JavaScript
- Local application storage
- GitHub Actions for automated APK builds

## Project Structure

```text
Business360/
├── app/
│   ├── src/main/
│   │   ├── assets/        # Web application UI and business logic
│   │   └── java/          # Android application layer
│   └── build.gradle
├── .github/workflows/     # Automated Android build workflow
└── README.md
```

## Build the APK

The repository includes a GitHub Actions workflow for building the Android application.

### Local build

```bash
gradle --no-daemon clean assembleDebug
```

The generated debug APK is placed under:

```text
app/build/outputs/apk/debug/app-debug.apk
```

### GitHub Actions

The workflow in `.github/workflows/build-apk.yml` builds the Android project directly from the repository source and publishes the generated APK as a workflow artifact.

## Development Focus

Business360 is an active portfolio project focused on:

- Practical business workflows
- Responsive mobile UI
- Persistent user preferences
- Touch-friendly interactions
- Maintainable Android/WebView integration
- Automated build and delivery

## Developer

**Md Sahadul Hoque Rumu**  
Founder & Developer — Business360  
Bangladesh

This repository represents an end-to-end product development project covering interface design, business logic, Android packaging, build automation, and iterative feature development.

## Project Status

Active development. Features and UI continue to evolve as the application is refined for real-world business use.
