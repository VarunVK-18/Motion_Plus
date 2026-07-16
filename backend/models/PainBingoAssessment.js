const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  selected_pain_areas: [String],
  pain_intensity: Number
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });
module.exports = mongoose.model('PainBingoAssessment', schema);
