const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  basic_info: { type: mongoose.Schema.Types.Mixed },
  referral_info: { type: mongoose.Schema.Types.Mixed },
  primary_complaint: String,
  problem_duration: String,
  onset: String,
  pain_scale: Number,
  symptoms: [String],
  functional_limitation: [String],
  severity: String,
  patient_goal: [String],
  medical_history: { type: mongoose.Schema.Types.Mixed },
  medication: String,
  lifestyle: { type: mongoose.Schema.Types.Mixed },
  falls_history: Boolean,
  assistive_device: String,
  home_exercise_compliance: String,
  consent: Boolean
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('PatientIntakeForm', schema);
