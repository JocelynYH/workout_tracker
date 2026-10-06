// Seeds a user's Exercises list from a workout program so you don't have to
// type each one into the app by hand. Safe to re-run — exercises the API
// reports as already existing (409) are skipped.
//
// Usage:
//   BASE_URL=http://localhost:3000 EMAIL=you@example.com PASSWORD=yourpassword node scripts/seed-exercises.js
//
// If the account doesn't exist yet, it's registered automatically.

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const EMAIL = process.env.EMAIL;
const PASSWORD = process.env.PASSWORD;

if (!EMAIL || !PASSWORD) {
  console.error('Set EMAIL and PASSWORD env vars (and optionally BASE_URL).');
  process.exit(1);
}

// Exercises from the "Phase One — 3 day a week" program (Days 1-6), deduped.
const exercises = [
  // Legs
  { name: 'Leg Extensions', category: 'Legs' },
  { name: 'Leg Press', category: 'Legs' },
  { name: 'Leg Curls', category: 'Legs' },
  { name: 'Inner Thigh', category: 'Legs' },
  { name: 'Outer Thigh', category: 'Legs' },
  { name: 'Standing Calf Raise', category: 'Legs' },
  { name: 'Seated Calf Raise', category: 'Legs' },
  { name: 'Walking Lunges', category: 'Legs' },
  { name: 'Squat #1', category: 'Legs' },
  { name: 'Butt Kicks', category: 'Legs' },
  // Chest
  { name: 'Flat Bench Dumbbell Press', category: 'Chest' },
  { name: 'Inclined Bench Press', category: 'Chest' },
  { name: 'Push-ups', category: 'Chest' },
  // Back
  { name: 'Lat Pull Down', category: 'Back' },
  { name: 'Seated Row', category: 'Back' },
  { name: 'One Arm Row', category: 'Back' },
  // Shoulders
  { name: 'W Shoulders', category: 'Shoulders' },
  { name: 'Lateral Raise', category: 'Shoulders' },
  { name: 'Delt Wing', category: 'Shoulders' },
  { name: 'Goal Posts', category: 'Shoulders' },
  { name: 'C-Sweep', category: 'Shoulders' },
  // Triceps
  { name: 'Tricep Pushdown', category: 'Triceps' },
  { name: 'Tricep Extensions', category: 'Triceps' },
  { name: 'Tricep Kickbacks with a Twist', category: 'Triceps' },
  { name: 'Overhead Tricep Extension', category: 'Triceps' },
  // Biceps
  { name: 'Curls', category: 'Biceps' },
  { name: 'Hammer Curls', category: 'Biceps' },
  { name: 'Cable Curls', category: 'Biceps' },
  { name: 'Concentration Curls', category: 'Biceps' },
  // Abs
  { name: 'Crunches', category: 'Abs' },
  { name: 'Bicycles', category: 'Abs' },
  { name: 'Toe Touches', category: 'Abs' },
  { name: 'Diagonal Crunch', category: 'Abs' },
  { name: 'Butt Lifts', category: 'Abs' },
  { name: 'Hand Crunch', category: 'Abs' },
  { name: 'Penguins', category: 'Abs' },
  { name: 'Side Crunches', category: 'Abs' },
  { name: 'Roman Sit-Ups', category: 'Abs' },
];

async function getToken() {
  const loginRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
  });
  if (loginRes.ok) return (await loginRes.json()).token;

  console.log('Login failed, trying to register a new account...');
  const registerRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
  });
  if (!registerRes.ok) {
    const body = await registerRes.json().catch(() => ({}));
    throw new Error(`Could not log in or register: ${body.error || registerRes.status}`);
  }
  return (await registerRes.json()).token;
}

async function main() {
  const token = await getToken();
  let created = 0;
  let skipped = 0;

  for (const exercise of exercises) {
    const res = await fetch(`${BASE_URL}/exercises`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(exercise),
    });

    if (res.status === 201) {
      created++;
      console.log(`+ ${exercise.name}`);
    } else if (res.status === 409) {
      skipped++;
    } else {
      const body = await res.json().catch(() => ({}));
      console.error(`! ${exercise.name}: ${body.error || res.status}`);
    }
  }

  console.log(`\nDone. Created ${created}, skipped ${skipped} already-existing.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
