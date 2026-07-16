const Profile = require('../models/Profile');

// @desc    Get all profiles (can filter by role)
// @route   GET /api/profiles
// @access  Private
const getProfiles = async (req, res) => {
    try {
        const query = {};
        if (req.query.role) {
            query.role = req.query.role;
        }
        if (req.query.clinic_id) {
            query.clinic_id = req.query.clinic_id;
        }
        if (req.query.specialization) {
            query.specialization = req.query.specialization;
        }
        
        // Populate clinic_id if needed to get clinic details automatically
        const profiles = await Profile.find(query)
                                      .sort({ created_at: -1 })
                                      .populate('clinic_id', 'name'); 
        res.json(profiles);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching profiles' });
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
    deleteProfile,
    updateProfile
};
