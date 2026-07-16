const mongoose = require('mongoose');

const smartAlertSchema = new mongoose.Schema({
  therapist_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: false },
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: false },
  message: { type: String, required: true },
  type: { type: String, default: 'info' }, // 'info', 'warning', 'critical'
  is_read: { type: Boolean, default: false },
  generated_at: { type: Date, default: Date.now },
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });

module.exports = mongoose.model('SmartAlert', smartAlertSchema);
