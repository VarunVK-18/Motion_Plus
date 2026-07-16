const SmartAlert = require('../models/SmartAlert');

exports.getAlerts = async (req, res) => {
    try {
        const query = {};
        if (req.query.is_read !== undefined) query.is_read = req.query.is_read === 'true';
        if (req.query.therapist_id) query.therapist_id = req.query.therapist_id;
        const alerts = await SmartAlert.find(query).sort({ generated_at: 1 });
        res.json(alerts.map(a => ({ ...a.toObject(), id: a._id.toString() })));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.updateAlert = async (req, res) => {
    try {
        const alert = await SmartAlert.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json({ ...alert.toObject(), id: alert._id.toString() });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};
