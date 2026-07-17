const Profile = require('../models/Profile');

// @desc    Get all profiles (can filter by role)
// @route   GET /api/profiles
// @access  Private
const getProfiles = async (req, res) => {
    try {
        const query = {};
        if (req.query.role) {
            if (req.query.role === 'therapist_assistant') {
                query.role = { $in: ['therapist', 'therapist_assistant'] };
            } else {
                query.role = req.query.role;
            }
        }
        if (req.query.clinic_id) {
            query.clinic_id = req.query.clinic_id;
        }
        if (req.query.specialization) {
            query.specialization = { $regex: new RegExp(`^${req.query.specialization}$`, 'i') };
        }
        
        // Populate clinic_id if needed to get clinic details automatically
        const profiles = await Profile.find(query)
                                      .sort({ created_at: -1 })
                                      .populate('clinic_id', 'name'); 
        res.json(profiles);
    } catch (error) {
        console.error('Error fetching profiles:', error);
        res.status(500).json({ message: 'Server error fetching profiles', error: error.message });
    }
};

// @desc    Get current user or specific user
// @route   GET /api/profiles/me or /api/profiles/:id
// @access  Private
const getProfile = async (req, res) => {
    try {
        let profileId = req.params.id;
        if (profileId === 'me') {
            profileId = req.user._id;
        }
        const profile = await Profile.findById(profileId).populate('clinic_id', 'name');
        if (!profile) {
            return res.status(404).json({ message: 'Profile not found' });
        }
        res.json(profile);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching profile' });
    }
};

// @desc    Delete a profile
// @route   DELETE /api/profiles/:id
// @access  Private
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

// @desc    Update a profile
// @route   PUT /api/profiles/:id
// @access  Private
const updateProfile = async (req, res) => {
    try {
        const updated = await Profile.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) return res.status(404).json({ message: 'Profile not found' });
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
