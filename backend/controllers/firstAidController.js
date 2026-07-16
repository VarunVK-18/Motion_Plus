const FirstAidCondition = require('../models/FirstAidCondition');

// @desc    Get all first aid conditions
// @route   GET /api/first_aid_conditions
const getConditions = async (req, res) => {
    try {
        const conditions = await FirstAidCondition.find({});
        res.json(conditions);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching conditions' });
    }
};

// @desc    Create a condition
// @route   POST /api/first_aid_conditions
const createCondition = async (req, res) => {
    try {
        const condition = await FirstAidCondition.create(req.body);
        res.status(201).json(condition);
    } catch (error) {
        res.status(500).json({ message: 'Server error creating condition' });
    }
};

module.exports = { getConditions, createCondition };
