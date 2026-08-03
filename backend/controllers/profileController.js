const Profile = require('../models/Profile');
const AuditLog = require('../models/AuditLog');

// ─────────────────────────────────────────────────────────────
// @desc    Get all profiles with multi-tenant data isolation
// @route   GET /api/profiles
// @route   GET /api/profiles?role=patient&clinic_id=xxx&branch_id=yyy
// @access  Private
//
// Access Rules:
//   superadmin   → can see everyone, no restrictions
//   admin        → can see all users in their clinic (all branches)
//   therapist    → can only see patients in their own branch
//   patient      → cannot call this endpoint (403)
// ─────────────────────────────────────────────────────────────
const getProfiles = async (req, res) => {
    try {
        const query = {};

        const role = req.user.role;
        const userClinicId = req.user.clinic_id?._id || req.user.clinic_id;
        const userBranchId = req.user.branch_id?._id || req.user.branch_id;

        // ── Scope by caller's role ────────────────────────────
        if (role === 'superadmin') {
            // No restriction — can see all data across all clinics
        } else if (role === 'admin') {
            query.clinic_id = userClinicId;
            // If the admin has a specific branch_id, they are a Branch Manager. Lock them to it!
            if (userBranchId) query.branch_id = userBranchId;
        } else if (role === 'therapist' || role === 'therapist_assistant') {
            // Therapists see data for any branches they are assigned to
            query.clinic_id = userClinicId;
            const branchIds = [];
            if (userBranchId) branchIds.push(userBranchId);
            if (req.user.branch_ids && req.user.branch_ids.length > 0) {
                branchIds.push(...req.user.branch_ids.map(b => b._id || b));
            }
            if (branchIds.length > 0) {
                query.$or = [{ branch_id: { $in: branchIds } }, { branch_ids: { $in: branchIds } }];
            }
        } else {
            return res.status(403).json({ message: 'Access denied' });
        }

        // ── Optional query param overrides (for filtering UI) ──
        if (req.query.role) {
            if (req.query.role === 'therapist_assistant') {
                query.role = { $in: ['therapist', 'therapist_assistant'] };
            } else {
                query.role = req.query.role;
            }
        }

        // Allow explicit clinic_id override ONLY for superadmin
        if (req.query.clinic_id && role === 'superadmin') {
            query.clinic_id = req.query.clinic_id;
        }

        // Allow explicit branch_id override
        if (req.query.branch_id) {
            query.branch_id = req.query.branch_id;
        }

        if (req.query.specialization) {
            query.specialization = { $regex: new RegExp(`^${req.query.specialization}$`, 'i') };
        }

        // Optional Pagination parameters
        const page = parseInt(req.query.page, 10);
        const limit = parseInt(req.query.limit, 10);

        if (!isNaN(page) && !isNaN(limit) && page > 0 && limit > 0) {
            const skip = (page - 1) * limit;
            const total = await Profile.countDocuments(query);
            const profiles = await Profile.find(query)
                .sort({ created_at: -1 })
                .skip(skip)
                .limit(limit)
                .populate('clinic_id', 'name')
                .populate('branch_id', 'name address');

            return res.json({
                data: profiles,
                page,
                totalPages: Math.ceil(total / limit),
                total
            });
        }

        const profiles = await Profile.find(query)
            .sort({ created_at: -1 })
            .populate('clinic_id', 'name')
            .populate('branch_id', 'name address');

        res.json(profiles);
    } catch (error) {
        console.error('Error fetching profiles:', error);
        res.status(500).json({ message: 'Server error fetching profiles', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Get single profile (me or by id)
// @route   GET /api/profiles/me
// @route   GET /api/profiles/:id
// @access  Private
// ─────────────────────────────────────────────────────────────
const getProfile = async (req, res) => {
    try {
        let profileId = req.params.id;
        if (profileId === 'me') {
            profileId = req.user._id;
        }
        const profile = await Profile.findById(profileId)
            .populate('clinic_id', 'name')
            .populate('branch_id', 'name address');
        if (!profile) {
            return res.status(404).json({ message: 'Profile not found' });
        }
        res.json(profile);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching profile' });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Delete a profile
// @route   DELETE /api/profiles/:id
// @access  Private (admin or superadmin)
// ─────────────────────────────────────────────────────────────
const deleteProfile = async (req, res) => {
    try {
        await Profile.findByIdAndDelete(req.params.id);
        const Session = require('../models/Session');
        await Session.deleteMany({ therapist_id: req.params.id });
        res.json({ message: 'Profile and associated sessions deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting profile' });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Update a profile (includes branch_id reassignment)
// @route   PUT /api/profiles/:id
// @access  Private
// ─────────────────────────────────────────────────────────────
const updateProfile = async (req, res) => {
    try {
        const updated = await Profile.findByIdAndUpdate(req.params.id, req.body, { new: true })
            .populate('clinic_id', 'name')
            .populate('branch_id', 'name address');
        if (!updated) return res.status(404).json({ message: 'Profile not found' });
        
        // Log the action
        if (req.user) {
            await AuditLog.create({
                action: 'UPDATE_PROFILE',
                performed_by: req.user._id,
                target_type: 'profile',
                target_id: updated._id,
                clinic_id: updated.clinic_id ? updated.clinic_id._id : null,
                details: { updated_fields: Object.keys(req.body) }
            });
        }
        
        res.json(updated);
    } catch (error) {
        res.status(500).json({ message: 'Server error updating profile' });
    }
};

module.exports = {
    getProfiles,
    getProfile,
    deleteProfile,
    updateProfile
};
