const Database = require('better-sqlite3');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const dbPath = path.join(__dirname, '..', 'mydompet.db');
const db = new Database(dbPath);

// Enable WAL mode for better performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT DEFAULT 'category',
    color TEXT DEFAULT '#6C63FF',
    type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
    is_default INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    category_id TEXT,
    type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
    amount REAL NOT NULL CHECK(amount > 0),
    description TEXT,
    date DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
  );

  CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
  CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
  CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
`);

/**
 * Seed default categories for a newly registered user.
 */
function seedDefaultCategories(userId) {
  const defaults = [
    // Expense categories
    { name: 'Makanan & Minuman', icon: 'restaurant', color: '#FF6B6B', type: 'expense' },
    { name: 'Transportasi', icon: 'directions_car', color: '#4ECDC4', type: 'expense' },
    { name: 'Belanja', icon: 'shopping_bag', color: '#FFE66D', type: 'expense' },
    { name: 'Hiburan', icon: 'movie', color: '#A8E6CF', type: 'expense' },
    { name: 'Tagihan', icon: 'receipt_long', color: '#FF8B94', type: 'expense' },
    { name: 'Kesehatan', icon: 'local_hospital', color: '#95E1D3', type: 'expense' },
    { name: 'Pendidikan', icon: 'school', color: '#F38181', type: 'expense' },
    { name: 'Lainnya', icon: 'more_horiz', color: '#AA96DA', type: 'expense' },
    // Income categories
    { name: 'Gaji', icon: 'account_balance_wallet', color: '#4CAF50', type: 'income' },
    { name: 'Freelance', icon: 'laptop', color: '#2196F3', type: 'income' },
    { name: 'Investasi', icon: 'trending_up', color: '#FF9800', type: 'income' },
    { name: 'Hadiah', icon: 'card_giftcard', color: '#E91E63', type: 'income' },
    { name: 'Lainnya', icon: 'more_horiz', color: '#9C27B0', type: 'income' },
  ];

  const stmt = db.prepare(`
    INSERT INTO categories (id, user_id, name, icon, color, type, is_default)
    VALUES (?, ?, ?, ?, ?, ?, 1)
  `);

  const insertMany = db.transaction((cats) => {
    for (const cat of cats) {
      stmt.run(uuidv4(), userId, cat.name, cat.icon, cat.color, cat.type);
    }
  });

  insertMany(defaults);
}

module.exports = { db, seedDefaultCategories };
