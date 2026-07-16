const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  sleep_quality: String,
  pain_level: Number,
  mood: String,
  notes: String
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('MorningCheckin', schema);
