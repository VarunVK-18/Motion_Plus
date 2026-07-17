const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getUserProfile, resetPassword, verifyOTP, updatePassword, updateFcmToken } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/me', protect, getUserProfile);
router.post('/fcm-token', protect, updateFcmToken);

// Password recovery endpoints
router.post('/reset-password', resetPassword);
router.post('/verify-otp', verifyOTP);
router.put('/update-password', protect, updatePassword);

module.exports = router;
