# SpendWise

SpendWise is a local-first Flutter personal finance app for tracking expenses,
monthly budgets, lending and borrowing, recurring payments, reports, backups,
notifications, and optional biometric app locking.

All financial data is stored locally on the device in SQLite. The app does not
require an account or a remote backend.

## Income and cash flow

The Income tab records money received, including the amount, source, date, and
optional notes. Reports highlight current-month cash flow:

```text
cash flow = income - expenses
```

Positive cash flow is shown in green and negative cash flow is shown in red.
Income records are included in local JSON backups and restore operations.

## Features

### Expense tracking

- Add, edit, search, filter, and delete expenses.
- Organize expenses with tags such as Personal, Household, Family, Work, Health,
  and Other.
- View expenses grouped by day.
- Swipe an expense from right to left to open the delete confirmation.
- Expenses are loaded with pagination; more records load automatically near the
  bottom of the list.
- Mark an expense as monthly recurring.

### Recurring expenses

Recurring expenses are represented as a series plus independent monthly
occurrences.

- Missing monthly occurrences are generated when the app starts.
- Missed months are caught up automatically.
- Each occurrence can be edited independently.
- When editing a generated occurrence, enable **Apply** beside the recurring
  option to apply changes to that occurrence and all future occurrences.
- Past occurrences are not changed by future edits.
- Deleting a recurring occurrence provides three choices:
  - Delete this occurrence only.
  - Stop future occurrences while keeping the selected occurrence.
  - Delete this and all future occurrences.
- Short months are handled safely; a recurring transaction scheduled on the 31st
  uses the last valid day when necessary.

### Budgets and insights

- Set a monthly budget.
- See current-month spending, budget usage, warnings, and over-budget status.
- Dashboard insights include today's spend, daily average, top category, logging
  streak, and top tag.
- Review monthly charts and category breakdowns.

### Lending and borrowing

- Track money lent to others and money borrowed from others.
- Group records by normalized phone number.
- Add another lent or borrowed transaction to an existing person from the
  three-dot menu.
- Record partial repayments and full settlements.
- Review repayment history.
- Send WhatsApp reminders for outstanding lent balances.

### Reports and backups

- Review annual spending totals and monthly breakdowns.
- Review outstanding lent and borrowed balances.
- Export all local data to a JSON backup.
- Import a JSON backup transactionally so an invalid restore does not partially
  overwrite the database.

### Security and reminders

- Optional biometric app lock using the device's supported authentication.
- Daily expense reminder notification scheduled for 9:00 PM.
- Light and dark themes.

## Technology stack

- Flutter and Dart
- Provider for application state
- SQLite through `sqflite`
- `path_provider` and `file_picker` for backup workflows
- `fl_chart` for charts
- `flutter_local_notifications` and `timezone` for reminders
- `local_auth` for biometric authentication
- `share_plus` for exporting backups

## Project structure

```text
lib/
├── database/
│   └── db_helper.dart              SQLite schema, migrations, queries
├── models/
│   ├── budget.dart
│   ├── expense.dart
│   └── lending_models.dart
├── providers/
│   ├── expense_provider.dart       Expenses, budgets, backups, pagination
│   ├── lending_provider.dart       Lent/borrowed state and repayments
│   ├── security_provider.dart      App-lock preference
│   └── theme_provider.dart         Theme preference
├── screens/
│   ├── dashboard/
│   ├── expense/
│   ├── lending/
│   ├── reports/
│   ├── budget/
│   ├── lock_screen.dart
│   └── main_screen.dart
├── utils/
│   ├── notification_service.dart
│   ├── theme.dart
│   ├── constants.dart
│   └── expense_type.dart
└── widgets/
```

The application starts in `lib/main.dart`, initializes notifications and
providers, loads local data, and then displays the splash, lock, or main screen.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Android SDK and an Android device or emulator for Android development
- Xcode for iOS/macOS development
- A desktop toolchain for Linux, Windows, or macOS desktop builds

Check the local installation with:

```bash
flutter doctor
```

## Development setup

Clone the repository and install dependencies:

```bash
git clone https://github.com/Sadam452/spendWise.git
cd spendwise
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run on a connected device:

```bash
flutter devices
flutter run -d <device-id>
```

Flutter runs in debug mode by default. During a debug session:

- Press `r` for hot reload.
- Press `R` for hot restart.
- Press `q` to stop the app.

## Android phone workflow

1. Enable Developer options and USB debugging on the phone.
2. Connect the phone by USB and unlock it.
3. Accept the USB debugging authorization prompt.
4. Confirm the device:

   ```bash
   adb devices
   flutter devices
   ```

5. Clean and run:

   ```bash
   flutter clean
   flutter pub get
   flutter run -d <device-id>
   ```

## Database and migrations

The database is created by `DBHelper` as `spendwise.db` in the platform's
application database directory. It currently contains tables for:

- `expenses`
- `income`
- `recurring_series`
- `recurring_skips`
- `lent_money`
- `borrowed_money`
- `budgets`
- `lending_transactions`

Schema changes must increment the database version and include an upgrade path.
Migrations should be idempotent because a mobile process can be interrupted
while opening or upgrading a database.

The database is device-local and is not committed to source control.

## Backup and restore

Use the Backup action in Reports to export a JSON file. The backup includes
expenses, recurring-series metadata, skipped recurring occurrences, budgets,
lending records, and repayment history.

Importing a backup replaces current local financial data inside a database
transaction. Keep backup files private because they contain financial records.

## App icon and branding

The application icon source is `assets/logo.png`. Platform launcher assets are
generated with `flutter_launcher_icons`.

After replacing the source logo, regenerate icons with:

```bash
flutter pub get
dart run flutter_launcher_icons
```

The generated assets cover Android, iOS, Web, Windows, and macOS.

## Notifications and permissions

The app requests notification permission where required and schedules a daily
reminder in the `Asia/Kolkata` timezone. Android notification and alarm
permissions are declared in the Android manifest.

Biometric authentication requires a device or emulator configured with a
supported lock method. Behavior varies by platform and device manufacturer.
## Building releases

Android debug build:

```bash
flutter build apk --debug
```

Android release build:

```bash
flutter build appbundle --release
```



## License

No license has been selected for this project yet.
