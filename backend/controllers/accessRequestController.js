const AccessRequest = require('../models/AccessRequest');

// @desc    Create a new access request
// @route   POST /api/access-requests
// @access  Private (Therapist only ideally)
const createAccessRequest = async (req, res) => {
    try {
        const { patient_id, reason } = req.body;
        
        // Ensure user is authenticated
        if (!req.user || !req.user._id) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        const newRequest = await AccessRequest.create({
            therapist_id: req.user._id,
            patient_id,
            reason,
            status: 'PENDING'
        });

        res.status(201).json(newRequest);
    } catch (error) {
        console.error('Error creating access request:', error);
        res.status(500).json({ message: 'Server error creating access request' });
    }
};

// @desc    Get access requests (can filter by therapist or patient)
// @route   GET /api/access-requests
// @access  Private
const getAccessRequests = async (req, res) => {
    try {
        const query = {};
        if (req.query.therapist_id) query.therapist_id = req.query.therapist_id;
        if (req.query.patient_id) query.patient_id = req.query.patient_id;
        if (req.query.status) query.status = req.query.status;

        const requests = await AccessRequest.find(query)
            .populate('therapist_id', 'first_name last_name email')
            .populate('patient_id', 'first_name last_name email')
            .sort({ created_at: -1 });

        res.json(requests);
    } catch (error) {
        console.error('Error fetching access requests:', error);
        res.status(500).json({ message: 'Server error fetching access requests' });
    }
};

module.exports = {
    createAccessRequest,
    getAccessRequests
};
