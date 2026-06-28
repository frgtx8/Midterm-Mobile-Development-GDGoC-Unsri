const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { db, seedDefaultCategories } = require('../database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Helper: generate tokens
function generateAccessToken(user) {
  return jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRATION || '15m' }
  );
}

function generateRefreshToken(user) {
  return jwt.sign(
    { userId: user.id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRATION || '7d' }
  );
}

// ─── REGISTER ────────────────────────────────────────────
router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { name, email, password } = req.body;

    try {
      // Check if user already exists
      const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
      if (existing) {
        return res.status(409).json({
          success: false,
          message: 'Email already registered.',
        });
      }

      // Hash password
      const salt = await bcrypt.genSalt(12);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Create user
      const userId = uuidv4();
      db.prepare('INSERT INTO users (id, name, email, password) VALUES (?, ?, ?, ?)').run(
        userId, name, email, hashedPassword
      );

      // Seed default categories
      seedDefaultCategories(userId);

      // Generate tokens
      const user = { id: userId, email };
      const accessToken = generateAccessToken(user);
      const refreshToken = generateRefreshToken(user);

      // Store refresh token
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      db.prepare('INSERT INTO refresh_tokens (id, user_id, token, expires_at) VALUES (?, ?, ?, ?)').run(
        uuidv4(), userId, refreshToken, expiresAt
      );

      res.status(201).json({
        success: true,
        message: 'Registration successful.',
        data: {
          user: { id: userId, name, email },
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── LOGIN ───────────────────────────────────────────────
router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { email, password } = req.body;

    try {
      const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password.',
        });
      }

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password.',
        });
      }

      const accessToken = generateAccessToken(user);
      const refreshToken = generateRefreshToken(user);

      // Store refresh token
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      db.prepare('INSERT INTO refresh_tokens (id, user_id, token, expires_at) VALUES (?, ?, ?, ?)').run(
        uuidv4(), user.id, refreshToken, expiresAt
      );

      res.json({
        success: true,
        message: 'Login successful.',
        data: {
          user: { id: user.id, name: user.name, email: user.email },
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
);

// ─── REFRESH TOKEN ───────────────────────────────────────
router.post('/refresh', (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ success: false, message: 'Refresh token is required.' });
  }

  try {
    // Verify the refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    // Check if refresh token exists in database
    const stored = db.prepare('SELECT * FROM refresh_tokens WHERE token = ? AND user_id = ?').get(
      refreshToken, decoded.userId
    );

    if (!stored) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token.' });
    }

    // Get user
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(decoded.userId);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found.' });
    }

    // Generate new access token
    const newAccessToken = generateAccessToken(user);

    res.json({
      success: true,
      data: { accessToken: newAccessToken },
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      // Remove expired refresh token
      db.prepare('DELETE FROM refresh_tokens WHERE token = ?').run(refreshToken);
      return res.status(401).json({ success: false, message: 'Refresh token expired. Please login again.' });
    }
    res.status(401).json({ success: false, message: 'Invalid refresh token.' });
  }
});

// ─── LOGOUT ──────────────────────────────────────────────
router.post('/logout', authenticate, (req, res) => {
  const { refreshToken } = req.body;

  // Remove specific refresh token or all tokens for user
  if (refreshToken) {
    db.prepare('DELETE FROM refresh_tokens WHERE token = ? AND user_id = ?').run(
      refreshToken, req.user.id
    );
  } else {
    db.prepare('DELETE FROM refresh_tokens WHERE user_id = ?').run(req.user.id);
  }

  res.json({ success: true, message: 'Logout successful.' });
});

// ─── GET PROFILE ─────────────────────────────────────────
router.get('/profile', authenticate, (req, res) => {
  const user = db.prepare('SELECT id, name, email, created_at FROM users WHERE id = ?').get(req.user.id);

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found.' });
  }

  res.json({ success: true, data: { user } });
});

// ─── UPDATE PROFILE ──────────────────────────────────────
router.put(
  '/profile',
  authenticate,
  [body('name').optional().trim().notEmpty().withMessage('Name cannot be empty')],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { name } = req.body;
    const updates = [];
    const values = [];

    if (name) {
      updates.push('name = ?');
      values.push(name);
    }

    if (updates.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update.' });
    }

    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(req.user.id);

    db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...values);

    const user = db.prepare('SELECT id, name, email, created_at FROM users WHERE id = ?').get(req.user.id);
    res.json({ success: true, data: { user } });
  }
);

module.exports = router;
