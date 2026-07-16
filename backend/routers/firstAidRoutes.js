const express = require('express');
const router = express.Router();
const { getConditions, createCondition } = require('../controllers/firstAidController');

router.route('/').get(getConditions).post(createCondition);

module.exports = router;
