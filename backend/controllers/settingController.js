const PlatformSetting = require('../models/PlatformSetting');

// @desc    Get all settings
// @route   GET /api/settings
// @access  Private
const getSettings = async (req, res) => {
    try {
        const settings = await PlatformSetting.find({});
        res.json(settings);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Upsert a setting
// @route   POST /api/settings
// @access  Private
const upsertSetting = async (req, res) => {
    try {
        const { key, value } = req.body;
        const setting = await PlatformSetting.findOneAndUpdate(
            { key },
            { value },
            { new: true, upsert: true }
        );
        res.json(setting);
    } catch (error) {
        res.status(500).json({ message: 'Server error upserting setting' });
    }
};

module.exports = {
    getSettings,
    upsertSetting,
};
