const express = require('express');
const router = express.Router();
const { createSession, getSessions, deleteSession, updateSession } = require('../controllers/sessionController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
    .post(protect, createSession)
    .get(protect, getSessions);

router.route('/:id')
    .delete(protect, deleteSession)
    .put(protect, updateSession);

module.exports = router;
