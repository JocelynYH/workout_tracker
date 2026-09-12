const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const rows = db
    .prepare('SELECT * FROM exercises WHERE user_id = ? ORDER BY name COLLATE NOCASE')
    .all(req.userId);
  res.json({ exercises: rows.map(toPublic) });
});

router.post('/', (req, res) => {
  const { name, category } = req.body || {};
  if (typeof name !== 'string' || !name.trim()) {
    return res.status(400).json({ error: 'Exercise name is required' });
  }

  try {
    const info = db
      .prepare('INSERT INTO exercises (user_id, name, category) VALUES (?, ?, ?)')
      .run(req.userId, name.trim(), category || null);
    const row = db.prepare('SELECT * FROM exercises WHERE id = ?').get(info.lastInsertRowid);
    res.status(201).json({ exercise: toPublic(row) });
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'You already have an exercise with that name' });
    }
    throw err;
  }
});

router.put('/:id', (req, res) => {
  const exercise = findOwnedExercise(req.userId, req.params.id);
  if (!exercise) return res.status(404).json({ error: 'Exercise not found' });

  const { name, category } = req.body || {};
  const newName = typeof name === 'string' && name.trim() ? name.trim() : exercise.name;
  const newCategory = category !== undefined ? category : exercise.category;

  db.prepare('UPDATE exercises SET name = ?, category = ? WHERE id = ?').run(
    newName,
    newCategory,
    exercise.id
  );
  const row = db.prepare('SELECT * FROM exercises WHERE id = ?').get(exercise.id);
  res.json({ exercise: toPublic(row) });
});

router.delete('/:id', (req, res) => {
  const exercise = findOwnedExercise(req.userId, req.params.id);
  if (!exercise) return res.status(404).json({ error: 'Exercise not found' });

  db.prepare('DELETE FROM exercises WHERE id = ?').run(exercise.id);
  res.status(204).end();
});

function findOwnedExercise(userId, id) {
  return db.prepare('SELECT * FROM exercises WHERE id = ? AND user_id = ?').get(id, userId);
}

function toPublic(row) {
  return { id: row.id, name: row.name, category: row.category, createdAt: row.created_at };
}

module.exports = router;
