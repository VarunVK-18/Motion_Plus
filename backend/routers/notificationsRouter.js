const express = require('express');
const router = express.Router();
const { scheduleNotification } = require('../controllers/notificationsController');
const { protect } = require('../middleware/authMiddleware');

router.post('/schedule-morning', protect, scheduleNotification);

module.exports = router;
