const mongoose = require('mongoose');

const prescribedExerciseSchema = new mongoose.Schema({
  patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  therapist_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
  exercise_name: { type: String, required: true },
  duration_minutes: { type: Number, default: 0 },
  sets: { type: Number, default: 0 },
  reps: { type: Number, default: 0 },
  notes: { type: String, default: '' },
}, { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } });

module.exports = mongoose.model('PrescribedExercise', prescribedExerciseSchema);
