const Session = require('../models/Session');
const Profile = require('../models/Profile');
const PatientAchievement = require('../models/PatientAchievement');
const AuditLog = require('../models/AuditLog');
const { sendPushNotification } = require('../firebaseAdmin');

// ─────────────────────────────────────────────────────────────
// @desc    Create a session (appointment)
// @route   POST /api/sessions
// @access  Private
// ─────────────────────────────────────────────────────────────
const createSession = async (req, res) => {
    try {
        const {
            patient_id, clinic_id, branch_id,
            specialization_required, fee_charged,
            status, location, scheduled_at,
            scheduled_date, scheduled_time, session_count
        } = req.body;

        // If branch_id not provided in body, try to resolve from patient's profile
        let resolvedBranchId = branch_id;
        if (!resolvedBranchId && patient_id) {
            const patient = await Profile.findById(patient_id).select('branch_id');
            if (patient && patient.branch_id) {
                resolvedBranchId = patient.branch_id;
            }
        }

        const session = await Session.create({
            patient_id,
            clinic_id,
            branch_id: resolvedBranchId || null,
            specialization_required,
            fee_charged,
            status,
            location,
            scheduled_at,
            scheduled_date,
            scheduled_time,
            session_count: session_count || 1,
        });

        res.status(201).json(session);
    } catch (error) {
        console.error('Error creating session:', error);
        res.status(500).json({ message: 'Server error creating session', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Get sessions with multi-tenant data isolation
// @route   GET /api/sessions
// @access  Private
//
// Access Rules:
//   superadmin   → all sessions
//   admin        → all sessions in their clinic
//   therapist    → sessions in their branch (or assigned to them)
//   patient      → only their own sessions
// ─────────────────────────────────────────────────────────────
const getSessions = async (req, res) => {
    try {
        const query = {};
        const role = req.user.role;
        const userClinicId = req.user.clinic_id?._id || req.user.clinic_id;
        const userBranchId = req.user.branch_id?._id || req.user.branch_id;

        // ── Scope by role ─────────────────────────────────────
        if (role === 'superadmin') {
            // No restriction
        } else if (role === 'admin') {
            query.clinic_id = userClinicId;
            if (userBranchId) query.branch_id = userBranchId; // Branch Manager support
        } else if (role === 'therapist' || role === 'therapist_assistant') {
            query.clinic_id = userClinicId;
            const branchIds = [];
            if (userBranchId) branchIds.push(userBranchId);
            if (req.user.branch_ids && req.user.branch_ids.length > 0) {
                branchIds.push(...req.user.branch_ids.map(b => b._id || b));
            }
            if (branchIds.length > 0) {
                query.branch_id = { $in: branchIds };
            }
        } else if (role === 'patient') {
            query.patient_id = req.user._id;
        }

        // ── Optional query param overrides ────────────────────
        if (req.query.clinic_id && role === 'superadmin') query.clinic_id = req.query.clinic_id;
        if (req.query.branch_id) query.branch_id = req.query.branch_id;
        if (req.query.therapist_id) query.therapist_id = req.query.therapist_id;
        if (req.query.patient_id) query.patient_id = req.query.patient_id;
        if (req.query.status) query.status = req.query.status;

        // Optional Pagination parameters
        const page = parseInt(req.query.page, 10);
        const limit = parseInt(req.query.limit, 10);

        if (!isNaN(page) && !isNaN(limit) && page > 0 && limit > 0) {
            const skip = (page - 1) * limit;
            const total = await Session.countDocuments(query);
            const sessions = await Session.find(query)
                .sort({ scheduled_date: -1, scheduled_time: -1 })
                .skip(skip)
                .limit(limit)
                .populate('patient_id', 'full_name email phone')
                .populate('therapist_id', 'full_name email specialization')
                .populate('clinic_id', 'name')
                .populate('branch_id', 'name address');

            return res.json({
                data: sessions,
                page,
                totalPages: Math.ceil(total / limit),
                total
            });
        }

        const sessions = await Session.find(query)
            .populate('patient_id', 'full_name email phone')
            .populate('therapist_id', 'full_name email specialization')
            .populate('clinic_id', 'name')
            .populate('branch_id', 'name address')
            .sort({ scheduled_date: -1, scheduled_time: -1 });

        res.json(sessions);
    } catch (error) {
        console.error('Error fetching sessions:', error);
        res.status(500).json({ message: 'Server error fetching sessions', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Delete a session
// @route   DELETE /api/sessions/:id
// @access  Private
// ─────────────────────────────────────────────────────────────
const deleteSession = async (req, res) => {
    try {
        await Session.findByIdAndDelete(req.params.id);
        res.json({ message: 'Session deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting session' });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Update a session (status, notes, therapist, etc.)
// @route   PUT /api/sessions/:id
// @access  Private
// ─────────────────────────────────────────────────────────────
const updateSession = async (req, res) => {
    try {
        const oldSession = await Session.findById(req.params.id);
        const updated = await Session.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) {
            return res.status(404).json({ message: 'Session not found' });
        }

        // Send FCM push notifications on status change
        if (oldSession && updated.status !== oldSession.status) {
            const patient = await Profile.findById(updated.patient_id);
            if (patient && patient.fcmTokens && patient.fcmTokens.length > 0) {
                let title = '';
                let body = '';
                if (updated.status === 'in-progress' || updated.status === 'in_progress') {
                    title = 'Session Started';
                    body = 'Your therapy session has started. Please join now.';
                } else if (updated.status === 'completed') {
                    title = 'Session Completed';
                    body = 'Your therapy session has been completed.';

                    // Milestone badge every 5 completed sessions
                    if (updated.completed_count > 0 && updated.completed_count % 5 === 0) {
                        const badgeName = `${updated.completed_count} Sessions Completed!`;
                        const badgeIcon = '🏆';

                        await sendPushNotification(
                            patient.fcmTokens,
                            'Milestone Reached! 🎉',
                            `You've completed ${updated.completed_count} sessions! Keep up the great work!`,
                            { type: 'contextual' }
                        );

                        await PatientAchievement.create({
                            patient_id: updated.patient_id,
                            badge_name: badgeName,
                            badge_icon: badgeIcon,
                        });
                    }
                }

                if (title && body) {
                    await sendPushNotification(patient.fcmTokens, title, body, { type: 'session' });
                }
            }
        }

        // Log the action
        if (req.user) {
            await AuditLog.create({
                action: 'UPDATE_SESSION',
                performed_by: req.user._id,
                target_type: 'session',
                target_id: updated._id,
                clinic_id: updated.clinic_id ? updated.clinic_id : null,
                details: { updated_fields: Object.keys(req.body) }
            });
        }

        res.json(updated);
    } catch (error) {
        console.error('Error updating session:', error);
        res.status(500).json({ message: 'Server error updating session', error: error.message });
    }
};

module.exports = {
    createSession,
    getSessions,
    deleteSession,
    updateSession
};
