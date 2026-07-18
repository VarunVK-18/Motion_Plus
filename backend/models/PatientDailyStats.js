const mongoose = require('mongoose');

const patientDailyStatsSchema = new mongoose.Schema({
    patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    date: { type: String, required: true }, // Format YYYY-MM-DD
    steps: { type: Number, default: 0 },
    water_glasses: { type: Number, default: 0 },
    water_goal: { type: Number, default: 8 },
    exercises_completed: { type: Boolean, default: false },
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });

// Ensure one entry per patient per day
patientDailyStatsSchema.index({ patient_id: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('PatientDailyStats', patientDailyStatsSchema);
