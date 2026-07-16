const express = require('express');
const router = express.Router();
const { getSettings, upsertSetting } = require('../controllers/settingController');

router.route('/')
    .get(getSettings)
    .post(upsertSetting);

module.exports = router;
