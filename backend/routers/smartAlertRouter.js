const express = require('express');
const router = express.Router();
const controller = require('../controllers/smartAlertController');

router.get('/', controller.getAlerts);
router.put('/:id', controller.updateAlert);

module.exports = router;
