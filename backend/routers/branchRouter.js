const express = require('express');
const router = express.Router();
const {
    getBranches,
    getBranchById,
    createBranch,
    updateBranch,
    deleteBranch,
} = require('../controllers/branchController');
const { protect } = require('../middleware/authMiddleware');

// GET /api/branches/public   — public list of branches (used by patient signup)
router.get('/public', getBranches);

// GET /api/branches          — list all branches (filtered by clinic for non-superadmins)
// POST /api/branches         — create a new branch
router.route('/')
    .get(protect, getBranches)
    .post(protect, createBranch);

// GET  /api/branches/:id     — get single branch
// PUT  /api/branches/:id     — update branch
// DELETE /api/branches/:id   — delete branch
router.route('/:id')
    .get(protect, getBranchById)
    .put(protect, updateBranch)
    .delete(protect, deleteBranch);

module.exports = router;
