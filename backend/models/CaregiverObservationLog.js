const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  caregiver_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile' },
  observation: String,
  severity: String
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('CaregiverObservationLog', schema);
