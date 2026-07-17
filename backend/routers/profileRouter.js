const express = require('express');
const router = express.Router();
const { getProfiles, getProfile, deleteProfile, updateProfile } = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getProfiles);
router.route('/:id')
    .get(protect, getProfile)
    .delete(protect, deleteProfile)
    .put(protect, updateProfile);

module.exports = router;
