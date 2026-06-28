const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// ─── GET SUMMARY ─────────────────────────────────────────
// Must be defined BEFORE /:id to avoid route conflict
router.get('/summary', (req, res) => {
  try {
    const { month, year } = req.query;

    let dateFilter = '';
    const params = [req.user.id];

    if (month && year) {
      dateFilter = "AND strftime('%m', date) = ? AND strftime('%Y', date) = ?";
      params.push(month.toString().padStart(2, '0'), year.toString());
    } else if (year) {
      dateFilter = "AND strftime('%Y', date) = ?";
      params.push(year.toString());
    }

    const income = db.prepare(`
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions WHERE user_id = ? AND type = 'income' ${dateFilter}
    `).get(...params);

    const expense = db.prepare(`
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions WHERE user_id = ? AND type = 'expense' ${dateFilter}
    `).get(...params);

    // Category breakdown for expenses
    const expenseByCategory = db.prepare(`
      SELECT c.name as category_name, c.icon as category_icon, c.color as category_color,
             COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.type = 'expense' ${dateFilter}
      GROUP BY t.category_id
      ORDER BY total DESC
    `).all(...params);

    // Category breakdown for income
    const incomeByCategory = db.prepare(`
      SELECT c.name as category_name, c.icon as category_icon, c.color as category_color,
             COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.type = 'income' ${dateFilter}
      GROUP BY t.category_id
      ORDER BY total DESC
    `).all(...params);

    // Monthly trend (last 6 months)
    const monthlyTrend = db.prepare(`
      SELECT strftime('%Y-%m', date) as month,
             SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
             SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE user_id = ? AND date >= date('now', '-6 months')
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
    `).all(req.user.id);

    res.json({
      success: true,
      data: {
        totalIncome: income.total,
        totalExpense: expense.total,
        balance: income.total - expense.total,
        expenseByCategory,
        incomeByCategory,
        monthlyTrend,
      },
    });
  } catch (error) {
    console.error('Summary error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// ─── GET ALL TRANSACTIONS ────────────────────────────────
router.get('/', (req, res) => {
  try {
    const { type, category_id, start_date, end_date, page = 1, limit = 20, sort = 'date', order = 'desc' } = req.query;

    let whereClause = 'WHERE t.user_id = ?';
    const params = [req.user.id];

    if (type && ['income', 'expense'].includes(type)) {
      whereClause += ' AND t.type = ?';
      params.push(type);
    }

    if (category_id) {
      whereClause += ' AND t.category_id = ?';
      params.push(category_id);
    }

    if (start_date) {
      whereClause += ' AND t.date >= ?';
      params.push(start_date);
    }

    if (end_date) {
      whereClause += ' AND t.date <= ?';
      params.push(end_date);
    }

    // Count total
    const countResult = db.prepare(`SELECT COUNT(*) as total FROM transactions t ${whereClause}`).get(...params);
    const total = countResult.total;

    // Sort
    const allowedSorts = ['date', 'amount', 'created_at'];
    const sortField = allowedSorts.includes(sort) ? sort : 'date';
    const sortOrder = order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    // Paginate
    const offset = (parseInt(page) - 1) * parseInt(limit);
    params.push(parseInt(limit), offset);

    const transactions = db.prepare(`
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ${whereClause}
      ORDER BY t.${sortField} ${sortOrder}
      LIMIT ? OFFSET ?
    `).all(...params);

    res.json({
      success: true,
      data: {
        transactions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// ─── GET TRANSACTION BY ID ───────────────────────────────
router.get('/:id', (req, res) => {
  try {
    const transaction = db.prepare(`
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.id = ? AND t.user_id = ?
    `).get(req.params.id, req.user.id);

    if (!transaction) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    res.json({ success: true, data: { transaction } });
  } catch (error) {
    console.error('Get transaction error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// ─── CREATE TRANSACTION ──────────────────────────────────
router.post(
  '/',
  [
    body('type').isIn(['income', 'expense']).withMessage('Type must be income or expense'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
    body('description').optional().trim(),
    body('category_id').optional().trim(),
    body('date').isISO8601().withMessage('Valid date is required'),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { type, amount, description, category_id, date } = req.body;
      const id = uuidv4();

      // Verify category belongs to user (if provided)
      if (category_id) {
        const cat = db.prepare('SELECT id FROM categories WHERE id = ? AND user_id = ?').get(
          category_id, req.user.id
        );
        if (!cat) {
          return res.status(400).json({ success: false, message: 'Invalid category.' });
        }
      }

      db.prepare(`
        INSERT INTO transactions (id, user_id, category_id, type, amount, description, date)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(id, req.user.id, category_id || null, type, amount, description || '', date);

      const transaction = db.prepare(`
        SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.id = ?
      `).get(id);

      res.status(201).json({
        success: true,
        message: 'Transaction created.',
        data: { transaction },
      });
    } catch (error) {
      console.error('Create transaction error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── UPDATE TRANSACTION ──────────────────────────────────
router.put(
  '/:id',
  [
    body('type').optional().isIn(['income', 'expense']),
    body('amount').optional().isFloat({ gt: 0 }),
    body('description').optional().trim(),
    body('category_id').optional().trim(),
    body('date').optional().isISO8601(),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      // Check ownership
      const existing = db.prepare('SELECT * FROM transactions WHERE id = ? AND user_id = ?').get(
        req.params.id, req.user.id
      );
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Transaction not found.' });
      }

      const { type, amount, description, category_id, date } = req.body;
      const updates = [];
      const values = [];

      if (type) { updates.push('type = ?'); values.push(type); }
      if (amount) { updates.push('amount = ?'); values.push(amount); }
      if (description !== undefined) { updates.push('description = ?'); values.push(description); }
      if (category_id) { updates.push('category_id = ?'); values.push(category_id); }
      if (date) { updates.push('date = ?'); values.push(date); }

      if (updates.length === 0) {
        return res.status(400).json({ success: false, message: 'No fields to update.' });
      }

      updates.push('updated_at = CURRENT_TIMESTAMP');
      values.push(req.params.id, req.user.id);

      db.prepare(`UPDATE transactions SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`).run(...values);

      const transaction = db.prepare(`
        SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.id = ?
      `).get(req.params.id);

      res.json({ success: true, message: 'Transaction updated.', data: { transaction } });
    } catch (error) {
      console.error('Update transaction error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── DELETE TRANSACTION ──────────────────────────────────
router.delete('/:id', (req, res) => {
  try {
    const existing = db.prepare('SELECT * FROM transactions WHERE id = ? AND user_id = ?').get(
      req.params.id, req.user.id
    );
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    db.prepare('DELETE FROM transactions WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);

    res.json({ success: true, message: 'Transaction deleted.' });
  } catch (error) {
    console.error('Delete transaction error:', error);
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

module.exports = router;
