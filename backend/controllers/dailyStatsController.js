const PatientDailyStats = require('../models/PatientDailyStats');

const updateDailyStats = async (req, res) => {
    try {
        const { date, steps, water_glasses, water_goal, exercises_completed } = req.body;
        const patient_id = req.user._id;

        if (!date) {
            return res.status(400).json({ message: 'Date is required (YYYY-MM-DD)' });
        }

        const updateData = {};
        if (steps !== undefined) updateData.steps = steps;
        if (water_glasses !== undefined) updateData.water_glasses = water_glasses;
        if (water_goal !== undefined) updateData.water_goal = water_goal;
        if (exercises_completed !== undefined) updateData.exercises_completed = exercises_completed;

        const stats = await PatientDailyStats.findOneAndUpdate(
            { patient_id, date },
            { $set: updateData },
            { new: true, upsert: true }
        );

        res.status(200).json({ message: 'Daily stats updated successfully', data: stats });
    } catch (error) {
        console.error('Error updating daily stats:', error);
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = {
    updateDailyStats
};
