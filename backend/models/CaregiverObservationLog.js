const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  logger_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile' },
  log_type: String,
  severity: Number,
  notes: String
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('CaregiverObservationLog', schema);
