const mongoose = require('mongoose');

const scheduledNotificationSchema = new mongoose.Schema({
    patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    scheduled_time: { type: Date, required: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    sent: { type: Boolean, default: false },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ScheduledNotification', scheduledNotificationSchema);
