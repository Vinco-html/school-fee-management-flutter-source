# School Fee Management

Flutter client for the school finance workspace. The same source adapts to mobile,
tablet, and desktop layouts.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-school-api.example.com/api
```

For local development:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api
```

The API base URL defaults to `http://localhost:5000/api`. The Node/Express API
and PostgreSQL schema live in `artifacts/api-server` and `lib/db`.

## Deploy the backend to Render

The repository root contains `render.yaml`, which configures a Render web
service for the API and a PostgreSQL database. In Render, create a new
Blueprint and select this repository. Render will install the pnpm workspace,
apply the Drizzle schema, and deploy the API with a health check at
`/api/healthz`.

After the web service is deployed, copy its HTTPS URL into the Flutter build:

```bash
flutter run --dart-define=API_BASE_URL=https://your-service.onrender.com/api
```

For a web release, use the same value with `flutter build web
--dart-define=API_BASE_URL=https://your-service.onrender.com/api`.

## Product roles

- **Admin**: dashboard, activity and notification visibility, payments and messaging.
- **Accountant**: add students, classes, record manual payments, and prepare parent campaigns.

The role switch in the demo shell is intentionally visible for previewing both
permission surfaces. Production authentication should bind the role to the
authenticated school user.