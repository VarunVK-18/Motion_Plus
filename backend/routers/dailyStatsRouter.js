const express = require('express');
const router = express.Router();
const { updateDailyStats } = require('../controllers/dailyStatsController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, updateDailyStats);

module.exports = router;
