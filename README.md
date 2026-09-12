# Workout Tracker

A personal workout logbook, digitized: a native iOS app for logging the sets,
reps, and weight you do each day (like the paper book, but on your phone),
backed by a small API server so your data is tied to your own account and can
sync across devices.

The project has two parts:

- **`backend/`** — a Node.js/Express API with its own SQLite database. Handles
  user accounts (email/password + JWT) and stores exercises and logged sets.
- **`ios/WorkoutTracker/`** — a SwiftUI iOS app (Xcode project) that logs in
  against the backend and lets you record workouts day by day.

## 1. Run the backend

You need Node.js 18+ installed.

```bash
cd backend
npm install
cp .env.example .env
# Edit .env and set JWT_SECRET to a long random string
npm start
```

This starts the API on `http://localhost:3000` (change `PORT` in `.env` if
needed) and creates a SQLite database file under `backend/data/`.

Quick sanity check:

```bash
curl http://localhost:3000/health
# {"status":"ok"}
```

To deploy it somewhere reachable from your phone (so you're not limited to
your computer's Wi-Fi), any small Node host works (Fly.io, Railway, a
Raspberry Pi, an old laptop, etc.) — just make sure `JWT_SECRET` is set and
the port is reachable.

### API overview

| Endpoint | Description |
|---|---|
| `POST /auth/register` | `{ email, password, displayName? }` → creates an account, returns a token |
| `POST /auth/login` | `{ email, password }` → returns a token |
| `GET /auth/me` | Current user (requires `Authorization: Bearer <token>`) |
| `GET /exercises` | List your exercises |
| `POST /exercises` | `{ name, category? }` → add an exercise |
| `DELETE /exercises/:id` | Remove an exercise |
| `GET /workouts?date=YYYY-MM-DD` | All sets logged on that date |
| `GET /workouts/history?exerciseId=` | All sets ever logged for one exercise |
| `POST /workouts` | `{ exerciseId, date, setNumber, reps?, weight?, notes? }` → log a set |
| `DELETE /workouts/:id` | Remove a logged set |

Every endpoint except `/auth/register`, `/auth/login`, and `/health` requires
the `Authorization: Bearer <token>` header from login/register.

## 2. Run the iOS app

Open `ios/WorkoutTracker/WorkoutTracker.xcodeproj` in Xcode (15 or newer,
targeting iOS 17+), then build and run on the Simulator or your device
(**⌘R**).

On first launch, go to the **Settings** tab and set the **server address** to
wherever your backend is running:

- Simulator, backend running on the same Mac: `http://localhost:3000` (the
  default) works as-is.
- Physical iPhone, backend running on your computer: use your computer's
  local network IP instead, e.g. `http://192.168.1.23:3000` (find it with
  `ipconfig getifaddr en0` on macOS). Your phone and computer need to be on
  the same Wi-Fi network.
- Backend deployed somewhere public: use that URL, e.g.
  `https://your-app.example.com`.

Then create an account from the login screen and start logging workouts.

### App structure

- **Today** — pick a date, add sets for whichever exercises you did that day
  (exercise, reps, weight, optional notes), grouped like a page in a logbook.
- **Exercises** — manage the list of exercises you track (add the ones from
  your book once, reuse them every day).
- **History** — pick an exercise and see every set you've ever logged for it,
  most recent first, so you can track progress over time.
- **Settings** — account info, log out, and the backend server address.

The auth token is stored in the iOS Keychain, so you stay logged in between
launches.

### Notes on HTTP vs HTTPS

The app's `Info.plist` allows plain HTTP to local-network addresses
(`NSAllowsLocalNetworking`) so it works against a backend on your home
network without extra setup. If you deploy the backend publicly, use HTTPS.
