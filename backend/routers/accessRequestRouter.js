const express = require('express');
const router = express.Router();
const { createAccessRequest, getAccessRequests } = require('../controllers/accessRequestController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
    .post(protect, createAccessRequest)
    .get(protect, getAccessRequests);

module.exports = router;
