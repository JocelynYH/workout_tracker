const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// GET /workouts?date=YYYY-MM-DD  -> all sets logged that day, joined with exercise info
router.get('/', (req, res) => {
  const { date } = req.query;
  if (!date || !DATE_RE.test(date)) {
    return res.status(400).json({ error: 'A date query param (YYYY-MM-DD) is required' });
  }

  const rows = db
    .prepare(
      `SELECT we.*, e.name AS exercise_name, e.category AS exercise_category
       FROM workout_entries we
       JOIN exercises e ON e.id = we.exercise_id
       WHERE we.user_id = ? AND we.entry_date = ?
       ORDER BY e.name COLLATE NOCASE, we.set_number ASC`
    )
    .all(req.userId, date);

  res.json({ entries: rows.map(toPublic) });
});

// GET /workouts/history?exerciseId=123  -> all sets ever logged for an exercise, most recent first
router.get('/history', (req, res) => {
  const { exerciseId } = req.query;
  if (!exerciseId) {
    return res.status(400).json({ error: 'exerciseId query param is required' });
  }

  const exercise = db
    .prepare('SELECT * FROM exercises WHERE id = ? AND user_id = ?')
    .get(exerciseId, req.userId);
  if (!exercise) return res.status(404).json({ error: 'Exercise not found' });

  const rows = db
    .prepare(
      `SELECT we.*, e.name AS exercise_name, e.category AS exercise_category
       FROM workout_entries we
       JOIN exercises e ON e.id = we.exercise_id
       WHERE we.user_id = ? AND we.exercise_id = ?
       ORDER BY we.entry_date DESC, we.set_number ASC`
    )
    .all(req.userId, exerciseId);

  res.json({ entries: rows.map(toPublic) });
});

router.post('/', (req, res) => {
  const { exerciseId, date, setNumber, reps, weight, notes } = req.body || {};

  if (!exerciseId || !date || !DATE_RE.test(date) || !setNumber) {
    return res
      .status(400)
      .json({ error: 'exerciseId, date (YYYY-MM-DD) and setNumber are required' });
  }

  const exercise = db
    .prepare('SELECT * FROM exercises WHERE id = ? AND user_id = ?')
    .get(exerciseId, req.userId);
  if (!exercise) return res.status(404).json({ error: 'Exercise not found' });

  const info = db
    .prepare(
      `INSERT INTO workout_entries (user_id, exercise_id, entry_date, set_number, reps, weight, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(req.userId, exerciseId, date, setNumber, reps ?? null, weight ?? null, notes || null);

  const row = db
    .prepare(
      `SELECT we.*, e.name AS exercise_name, e.category AS exercise_category
       FROM workout_entries we JOIN exercises e ON e.id = we.exercise_id
       WHERE we.id = ?`
    )
    .get(info.lastInsertRowid);

  res.status(201).json({ entry: toPublic(row) });
});

router.put('/:id', (req, res) => {
  const entry = db
    .prepare('SELECT * FROM workout_entries WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.userId);
  if (!entry) return res.status(404).json({ error: 'Entry not found' });

  const { setNumber, reps, weight, notes } = req.body || {};
  db.prepare(
    'UPDATE workout_entries SET set_number = ?, reps = ?, weight = ?, notes = ? WHERE id = ?'
  ).run(
    setNumber ?? entry.set_number,
    reps !== undefined ? reps : entry.reps,
    weight !== undefined ? weight : entry.weight,
    notes !== undefined ? notes : entry.notes,
    entry.id
  );

  const row = db
    .prepare(
      `SELECT we.*, e.name AS exercise_name, e.category AS exercise_category
       FROM workout_entries we JOIN exercises e ON e.id = we.exercise_id
       WHERE we.id = ?`
    )
    .get(entry.id);

  res.json({ entry: toPublic(row) });
});

router.delete('/:id', (req, res) => {
  const entry = db
    .prepare('SELECT * FROM workout_entries WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.userId);
  if (!entry) return res.status(404).json({ error: 'Entry not found' });

  db.prepare('DELETE FROM workout_entries WHERE id = ?').run(entry.id);
  res.status(204).end();
});

function toPublic(row) {
  return {
    id: row.id,
    exerciseId: row.exercise_id,
    exerciseName: row.exercise_name,
    exerciseCategory: row.exercise_category,
    date: row.entry_date,
    setNumber: row.set_number,
    reps: row.reps,
    weight: row.weight,
    notes: row.notes,
    createdAt: row.created_at,
  };
}

module.exports = router;
