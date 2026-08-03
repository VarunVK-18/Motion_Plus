const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    action: { type: String, required: true },
    performed_by: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    target_type: { type: String, required: true }, // e.g. 'profile', 'session'
    target_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    clinic_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Clinic' },
    details: { type: mongoose.Schema.Types.Mixed },
    created_at: { type: Date, default: Date.now }
}, { timestamps: true });

auditLogSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const AuditLog = mongoose.model('AuditLog', auditLogSchema);
module.exports = AuditLog;
