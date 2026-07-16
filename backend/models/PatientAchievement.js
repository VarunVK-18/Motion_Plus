const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  title: String,
  description: String,
  icon: String,
  unlocked_at: { type: Date, default: Date.now }
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('PatientAchievement', schema);
