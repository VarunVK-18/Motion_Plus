const express = require('express');
const router = express.Router();
const { getProfiles, deleteProfile, updateProfile } = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getProfiles);
router.route('/:id').delete(protect, deleteProfile).put(protect, updateProfile);

module.exports = router;
