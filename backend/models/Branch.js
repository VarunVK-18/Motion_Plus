const mongoose = require('mongoose');

/**
 * Branch Model
 * Represents a physical clinic location that belongs to a Clinic (company/chain).
 * Hierarchy: Platform -> Clinic (Company) -> Branch (Location) -> Profiles / Sessions
 */
const branchSchema = new mongoose.Schema({
    name:     { type: String, required: true, trim: true },
    clinic_id:{ type: mongoose.Schema.Types.ObjectId, ref: 'Clinic', required: true },
    address:  { type: String, trim: true },
    phone:    { type: String, trim: true },
    email:    { type: String, trim: true },
    is_active:{ type: Boolean, default: true },
}, { timestamps: true });

// Virtual id field for consistent API shape
branchSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const Branch = mongoose.model('Branch', branchSchema);
module.exports = Branch;
