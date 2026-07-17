const Session = require('../models/Session');
const Profile = require('../models/Profile');
const { sendPushNotification } = require('../firebaseAdmin');

// @desc    Create a session
// @route   POST /api/sessions
// @access  Private
const createSession = async (req, res) => {
    try {
        const { patient_id, clinic_id, specialization_required, fee_charged, status, location, scheduled_at } = req.body;

        const session = await Session.create({
            patient_id,
            clinic_id,
            specialization_required,
            fee_charged,
            status,
            location,
            scheduled_at
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
        const oldSession = await Session.findById(req.params.id);
        const updated = await Session.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) {
            return res.status(404).json({ message: 'Session not found' });
        }

        // Check if status changed
        if (oldSession && updated.status !== oldSession.status) {
            const patient = await Profile.findById(updated.patient_id);
            if (patient && patient.fcmTokens && patient.fcmTokens.length > 0) {
                let title = '';
                let body = '';
                if (updated.status === 'in-progress') {
                    title = 'Session Started';
                    body = 'Your therapy session has started. Please join now.';
                } else if (updated.status === 'completed') {
                    title = 'Session Completed';
                    body = 'Your therapy session has been completed.';
                }

                if (title && body) {
                    await sendPushNotification(patient.fcmTokens, title, body, { type: 'session' });
                }
            }
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
