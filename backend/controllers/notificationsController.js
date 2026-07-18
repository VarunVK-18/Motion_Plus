const ScheduledNotification = require('../models/ScheduledNotification');

const scheduleNotification = async (req, res) => {
    try {
        const { scheduled_time, title, body } = req.body;
        
        if (!scheduled_time || !title || !body) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        const newNotification = new ScheduledNotification({
            patient_id: req.user._id,
            scheduled_time: new Date(scheduled_time),
            title,
            body
        });

        await newNotification.save();
        res.status(201).json({ message: 'Notification scheduled successfully', data: newNotification });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = {
    scheduleNotification
};
