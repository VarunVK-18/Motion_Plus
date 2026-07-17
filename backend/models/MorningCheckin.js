const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  session_id: { type: String },
  overall_day: String,
  active_level: String,
  home_exercises: String,
  pain_discomfort: String,
  energy_level: String,
  sleep_quality: String,
  symptoms: [String],
  mood: String,
  difficulty_activities: [String],
  important_note: [String],
  readiness_score: Number,
  compliance_score: Number,
  smart_notifications: [String],
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('MorningCheckin', schema);
