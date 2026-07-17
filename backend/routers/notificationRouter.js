const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

router.post('/push', notificationController.pushNotification);

module.exports = router;
