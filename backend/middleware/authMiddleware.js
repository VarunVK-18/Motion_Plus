const jwt = require('jsonwebtoken');
const Profile = require('../models/Profile');

// ─────────────────────────────────────────────────────────────
// protect — verifies JWT and attaches req.user (with clinic_id & branch_id populated)
// ─────────────────────────────────────────────────────────────
const protect = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');

            // Populate clinic_id and branch_id so controllers can use them directly
            req.user = await Profile.findById(decoded.id)
                .select('-password')
                .populate('clinic_id', '_id name subscription_status')
                .populate('branch_id', '_id name');

            if (!req.user) {
                return res.status(401).json({ message: 'Not authorized, user not found' });
            }

            // Check if the user's clinic is suspended (superadmin bypasses this)
            if (req.user.role !== 'superadmin' && req.user.clinic_id && req.user.clinic_id.subscription_status === 'suspended') {
                return res.status(403).json({ message: 'Access denied. Your clinic account is currently suspended.' });
            }

            next();
        } catch (error) {
            console.error('Auth middleware error:', error);
            res.status(401).json({ message: 'Not authorized, token failed' });
        }
    } else {
        res.status(401).json({ message: 'Not authorized, no token' });
    }
};

// ─────────────────────────────────────────────────────────────
// requireRoles — restricts a route to specific roles
// Usage: router.get('/admin-only', protect, requireRoles('admin','superadmin'), handler)
// ─────────────────────────────────────────────────────────────
const requireRoles = (...roles) => {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            return res.status(403).json({
                message: `Access denied. Required role(s): ${roles.join(', ')}`
            });
        }
        next();
    };
};

module.exports = { protect, requireRoles };
