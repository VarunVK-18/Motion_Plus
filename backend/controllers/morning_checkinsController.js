const MorningCheckin = require('../models/MorningCheckin');

exports.getAll = async (req, res) => {
    try {
        const query = {};
        if (req.query.patient_id) query.patient_id = req.query.patient_id;
        const items = await MorningCheckin.find(query).sort({ created_at: -1 });
        res.json(items.map(item => ({ ...item.toObject(), id: item._id.toString() })));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.create = async (req, res) => {
    try {
        const item = new MorningCheckin(req.body);
        await item.save();
        res.status(201).json({ ...item.toObject(), id: item._id.toString() });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.update = async (req, res) => {
    try {
        const item = await MorningCheckin.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json({ ...item.toObject(), id: item._id.toString() });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.delete = async (req, res) => {
    try {
        await MorningCheckin.findByIdAndDelete(req.params.id);
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
