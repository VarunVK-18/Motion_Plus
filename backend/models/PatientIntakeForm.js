const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  medical_history: String,
  current_medications: String,
  allergies: String,
  emergency_contact: String
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('PatientIntakeForm', schema);
