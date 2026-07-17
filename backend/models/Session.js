const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
    patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    clinic_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Clinic', required: true },
    therapist_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile' },
    specialization_required: { type: String, default: 'ortho' },
    fee_charged: { type: Number, required: true },
    status: { type: String, enum: ['pending', 'requested', 'assigned', 'in_progress', 'completed', 'cancelled'], default: 'pending' },
    location: { type: String, default: 'TBD' },
    scheduled_at: { type: Date },
    scheduled_date: { type: String },
    scheduled_time: { type: String },
    started_at: { type: Date },
    allotted_time: { type: Number },
    session_count: { type: Number, default: 1 },
    completed_count: { type: Number, default: 0 },
    completed_at: { type: Date },
    session_summary: { type: String },
    exercises_performed: { type: String },
    pain_fatigue_level: { type: String },
    patient_response: { type: String },
    therapist_observation: { type: String },
    homework_given: { type: String },
    session_recommendation: { type: String },
    patient_feedback: { type: String },
    created_at: { type: Date, default: Date.now }
}, { timestamps: true });

sessionSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const Session = mongoose.model('Session', sessionSchema);
module.exports = Session;
