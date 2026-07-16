const mongoose = require('mongoose');

const accessRequestSchema = new mongoose.Schema({
    therapist_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    patient_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    reason: { type: String, required: true },
    status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'], default: 'PENDING' },
    created_at: { type: Date, default: Date.now },
}, { timestamps: true });

// Transform _id to id
accessRequestSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const AccessRequest = mongoose.model('AccessRequest', accessRequestSchema);
module.exports = AccessRequest;
