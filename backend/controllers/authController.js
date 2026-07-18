const Profile = require('../models/Profile');
const generateToken = require('../utils/generateToken');
const bcrypt = require('bcryptjs');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = async (req, res) => {
    try {
        const { first_name, last_name, phone, role, email, password, clinic_id, specialization } = req.body;

        if (!email || !/^\S+@\S+\.\S+$/.test(email)) {
            return res.status(400).json({ message: 'Invalid email format' });
        }
        
        if (!password || password.length < 8) {
            return res.status(400).json({ message: 'Password must be at least 8 characters' });
        }

        const userExists = await Profile.findOne({ email });

        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const full_name = `${first_name} ${last_name}`;

        const user = await Profile.create({
            first_name,
            last_name,
            full_name,
            phone,
            role,
            email,
            password,
            clinic_id,
            specialization
        });

        if (user) {
            res.status(201).json({
                _id: user._id,
                first_name: user.first_name,
                last_name: user.last_name,
                email: user.email,
                role: user.role,
                token: generateToken(user._id),
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        console.error('Error in register:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Case-insensitive email lookup
        const user = await Profile.findOne({ email: { $regex: new RegExp(`^${email.trim()}$`, 'i') } });

        if (!user) {
            return res.status(401).json({ message: 'invalid email id' });
        }

        if (!(await user.matchPassword(password))) {
            return res.status(401).json({ message: 'your entered password is wrong' });
        }

        res.json({
            _id: user._id,
            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,
            email: user.email,
            role: user.role,
            clinic_id: user.clinic_id,
            token: generateToken(user._id),
        });
    } catch (error) {
        console.error('Error in login:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Get user profile
// @route   GET /api/auth/me
// @access  Private
const getUserProfile = async (req, res) => {
    try {
        const user = await Profile.findById(req.user._id);

        if (user) {
            res.json(user);
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Mock send OTP
// @route   POST /api/auth/reset-password
const resetPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await Profile.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ message: 'OTP sent successfully (mocked)' });
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Mock verify OTP
// @route   POST /api/auth/verify-otp
const verifyOTP = async (req, res) => {
    try {
        const { email, token } = req.body;
        const user = await Profile.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });
        
        // Mock verification
        if (token === '123456') { // Allow 123456 as a mock OTP for testing
            res.json({ 
                message: 'OTP verified', 
                token: generateToken(user._id) // log them in so they can update password
            });
        } else {
            res.status(400).json({ message: 'Invalid OTP' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Update password
// @route   PUT /api/auth/update-password
const updatePassword = async (req, res) => {
    try {
        const { password } = req.body;
        const user = await Profile.findById(req.user._id);
        if (user) {
            user.password = password;
            await user.save();
            res.json({ message: 'Password updated' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

const updateFcmToken = async (req, res) => {
    try {
        const { token } = req.body;
        if (!token) {
            return res.status(400).json({ message: 'Token is required' });
        }
        
        const user = await Profile.findById(req.user._id);
        if (user) {
            if (!user.fcmTokens) {
                user.fcmTokens = [];
            }
            if (!user.fcmTokens.includes(token)) {
                user.fcmTokens.push(token);
                await user.save();
            }
            res.json({ message: 'Token updated successfully' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getUserProfile,
    resetPassword,
    verifyOTP,
    updatePassword,
    updateFcmToken,
};
