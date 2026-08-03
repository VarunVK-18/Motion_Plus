const mongoose = require('mongoose');

const clinicSchema = new mongoose.Schema({
    name: { type: String, required: true },
    company_code: { type: String, unique: true },
    address: { type: String },
    phone: { type: String },
    email: { type: String },
    subscription_status: { type: String, enum: ['active', 'suspended'], default: 'active' },
    subscription_plan: { type: String, enum: ['basic', 'premium', 'enterprise'], default: 'basic' },
    subscription_expiry: { type: Date },
    amount_paid: { type: Number, default: 0 },
    pricing: {
        type: Map,
        of: String, // e.g. "pkg_Session-based Packages": "500"
        default: {}
    },
    created_at: { type: Date, default: Date.now }
}, { timestamps: true });

clinicSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const Clinic = mongoose.model('Clinic', clinicSchema);
module.exports = Clinic;
