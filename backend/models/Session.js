const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
    patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    clinic_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Clinic', required: true },
    therapist_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile' },
    specialization_required: { type: String, default: 'ortho' },
    fee_charged: { type: Number, required: true },
    status: { type: String, enum: ['pending', 'assigned', 'completed', 'cancelled'], default: 'pending' },
    location: { type: String, default: 'TBD' },
    scheduled_at: { type: Date },
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
