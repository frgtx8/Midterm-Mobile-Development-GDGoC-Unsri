const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// ─── GET ALL CATEGORIES ──────────────────────────────────
router.get('/', (req, res) => {
  try {
    const { type } = req.query;

    let query = 'SELECT * FROM categories WHERE user_id = ?';
    const params = [req.user.id];

    if (type && ['income', 'expense'].includes(type)) {
      query += ' AND type = ?';
      params.push(type);
    }

    query += ' ORDER BY is_default DESC, name ASC';

    const categories = db.prepare(query).all(...params);

    res.json({ success: true, data: { categories } });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// ─── CREATE CATEGORY ─────────────────────────────────────
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('type').isIn(['income', 'expense']).withMessage('Type must be income or expense'),
    body('icon').optional().trim(),
    body('color').optional().trim(),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { name, type, icon, color } = req.body;
      const id = uuidv4();

      db.prepare(`
        INSERT INTO categories (id, user_id, name, icon, color, type, is_default)
        VALUES (?, ?, ?, ?, ?, ?, 0)
      `).run(id, req.user.id, name, icon || 'category', color || '#6C63FF', type);

      const category = db.prepare('SELECT * FROM categories WHERE id = ?').get(id);

      res.status(201).json({
        success: true,
        message: 'Category created.',
        data: { category },
      });
    } catch (error) {
      console.error('Create category error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── UPDATE CATEGORY ─────────────────────────────────────
router.put(
  '/:id',
  [
    body('name').optional().trim().notEmpty(),
    body('icon').optional().trim(),
    body('color').optional().trim(),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const existing = db.prepare('SELECT * FROM categories WHERE id = ? AND user_id = ?').get(
        req.params.id, req.user.id
      );
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Category not found.' });
      }

      const { name, icon, color } = req.body;
      const updates = [];
      const values = [];

      if (name) { updates.push('name = ?'); values.push(name); }
      if (icon) { updates.push('icon = ?'); values.push(icon); }
      if (color) { updates.push('color = ?'); values.push(color); }

      if (updates.length === 0) {
        return res.status(400).json({ success: false, message: 'No fields to update.' });
      }

      values.push(req.params.id, req.user.id);
      db.prepare(`UPDATE categories SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`).run(...values);

      const category = db.prepare('SELECT * FROM categories WHERE id = ?').get(req.params.id);
      res.json({ success: true, message: 'Category updated.', data: { category } });
    } catch (error) {
      console.error('Update category error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── DELETE CATEGORY ─────────────────────────────────────
router.delete('/:id', (req, res) => {
  try {
    const existing = db.prepare('SELECT * FROM categories WHERE id = ? AND user_id = ?').get(
      req.params.id, req.user.id
    );
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Category not found.' });
    }

    // Don't allow deleting default categories
    if (existing.is_default) {
      return res.status(400).json({ success: false, message: 'Cannot delete default categories.' });
    }

    db.prepare('DELETE FROM categories WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);

    res.json({ success: true, message: 'Category deleted.' });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

module.exports = router;
