const Session = require('../models/Session');

// @desc    Create a session
// @route   POST /api/sessions
// @access  Private
const createSession = async (req, res) => {
    try {
        const { patient_id, clinic_id, specialization_required, fee_charged, status, location } = req.body;

        const session = await Session.create({
            patient_id,
            clinic_id,
            specialization_required,
            fee_charged,
            status,
            location
        });

        res.status(201).json(session);
    } catch (error) {
        console.error('Error creating session:', error);
        res.status(500).json({ message: 'Server error creating session' });
    }
};

// @desc    Get all sessions
// @route   GET /api/sessions
// @access  Private
const getSessions = async (req, res) => {
    try {
        const query = {};
        if (req.query.clinic_id) query.clinic_id = req.query.clinic_id;
        if (req.query.therapist_id) query.therapist_id = req.query.therapist_id;
        if (req.query.patient_id) query.patient_id = req.query.patient_id;
        if (req.query.status) query.status = req.query.status;

        const sessions = await Session.find(query)
            .populate('patient_id', 'full_name email')
            .populate('therapist_id', 'full_name email')
            .populate('clinic_id', 'name')
            .sort({ created_at: -1 });

        res.json(sessions);
    } catch (error) {
        console.error('Error fetching sessions:', error);
        res.status(500).json({ message: 'Server error fetching sessions' });
    }
};

// @desc    Delete a session
// @route   DELETE /api/sessions/:id
// @access  Private
const deleteSession = async (req, res) => {
    try {
        await Session.findByIdAndDelete(req.params.id);
        res.json({ message: 'Session deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting session' });
    }
};

// @desc    Update a session
// @route   PUT /api/sessions/:id
// @access  Private
const updateSession = async (req, res) => {
    try {
        const updated = await Session.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) {
            return res.status(404).json({ message: 'Session not found' });
        }
        res.json(updated);
    } catch (error) {
        console.error('Error updating session:', error);
        res.status(500).json({ message: 'Server error updating session' });
    }
};

module.exports = {
    createSession,
    getSessions,
    deleteSession,
    updateSession
};
