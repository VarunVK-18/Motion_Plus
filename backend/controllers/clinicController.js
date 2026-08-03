const Clinic = require('../models/Clinic');
const Branch = require('../models/Branch');

// @desc    Get all clinics
// @route   GET /api/clinics
// @access  Public (needed for sign-up dropdown)
const getClinics = async (req, res) => {
    try {
        const clinics = await Clinic.find({}).sort({ name: 1 });
        res.json(clinics);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching clinics' });
    }
};

// @desc    Verify a clinic by company_code
// @route   GET /api/clinics/verify/:code
// @access  Public
const verifyClinicCode = async (req, res) => {
    try {
        const clinic = await Clinic.findOne({ company_code: req.params.code });
        if (!clinic) return res.status(404).json({ message: 'Invalid Clinic Code' });
        res.json({ id: clinic._id, name: clinic.name, company_code: clinic.company_code });
    } catch (error) {
        res.status(500).json({ message: 'Server error verifying clinic code' });
    }
};

// @desc    Get a single clinic with its branches
// @route   GET /api/clinics/:id
// @access  Private
const getClinicById = async (req, res) => {
    try {
        const clinic = await Clinic.findById(req.params.id);
        if (!clinic) return res.status(404).json({ message: 'Clinic not found' });

        // Also return branches for this clinic
        const branches = await Branch.find({ clinic_id: req.params.id }).sort({ name: 1 });
        res.json({ ...clinic.toJSON(), branches });
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching clinic', error: error.message });
    }
};

// @desc    Create a new clinic (company/chain)
// @route   POST /api/clinics
// @access  Private (superadmin)
const createClinic = async (req, res) => {
    try {
        const { name, address, phone, email, company_code: custom_code, subscription_plan, subscription_expiry, amount_paid } = req.body;
        if (!name) {
            return res.status(400).json({ message: 'Clinic name is required' });
        }
        
        let company_code = custom_code;
        
        if (!company_code) {
            const prefix = name.replace(/[^A-Za-z]/g, '').substring(0, 3).toUpperCase() || 'CLI';
            
            // Find the clinic with the highest sequence number for this prefix
            const lastClinic = await Clinic.findOne({ company_code: { $regex: `^${prefix}@` } })
                .sort({ createdAt: -1 });

            let nextNum = 1;
            if (lastClinic && lastClinic.company_code) {
                const parts = lastClinic.company_code.split('@');
                if (parts.length === 2) {
                    const lastNum = parseInt(parts[1], 10);
                    if (!isNaN(lastNum)) {
                        nextNum = lastNum + 1;
                    }
                }
            }
            company_code = `${prefix}@${nextNum}`;
        }
        
        // Ensure complete uniqueness with a fallback while loop just in case of edge race-conditions
        let original_code = company_code;
        let suffixNum = 1;
        while (await Clinic.exists({ company_code })) {
            company_code = `${original_code}_${suffixNum}`;
            suffixNum++;
        }

        const clinic = await Clinic.create({
            name,
            address,
            phone,
            email,
            company_code,
            subscription_plan: subscription_plan || 'basic',
            subscription_expiry: subscription_expiry || new Date(new Date().setFullYear(new Date().getFullYear() + 1)), // default 1 year
            amount_paid: amount_paid || 0
        });
        res.status(201).json(clinic);
    } catch (error) {
        res.status(500).json({ message: 'Server error creating clinic', error: error.message });
    }
};

// @desc    Update a clinic (including pricing)
// @route   PUT /api/clinics/:id
// @access  Private (superadmin or admin)
const updateClinic = async (req, res) => {
    try {
        const updated = await Clinic.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) return res.status(404).json({ message: 'Clinic not found' });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ message: 'Server error updating clinic', error: error.message });
    }
};

// @desc    Renew clinic subscription
// @route   POST /api/clinics/:id/renew
// @access  Private (superadmin)
const renewClinic = async (req, res) => {
    try {
        const { amount_paid, additional_months } = req.body;
        const clinic = await Clinic.findById(req.params.id);
        if (!clinic) return res.status(404).json({ message: 'Clinic not found' });

        const currentExpiry = clinic.subscription_expiry ? new Date(clinic.subscription_expiry) : new Date();
        const newExpiry = new Date(currentExpiry.setMonth(currentExpiry.getMonth() + (additional_months || 12)));

        clinic.subscription_expiry = newExpiry;
        clinic.amount_paid = (clinic.amount_paid || 0) + (amount_paid || 0);
        clinic.subscription_status = 'active';
        
        await clinic.save();
        res.json(clinic);
    } catch (error) {
        res.status(500).json({ message: 'Server error renewing clinic', error: error.message });
    }
};

// @desc    Delete a clinic
// @route   DELETE /api/clinics/:id
// @access  Private (superadmin)
const deleteClinic = async (req, res) => {
    try {
        // Also delete all branches belonging to this clinic
        await Branch.deleteMany({ clinic_id: req.params.id });
        await Clinic.findByIdAndDelete(req.params.id);
        res.json({ message: 'Clinic and its branches deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting clinic', error: error.message });
    }
};

module.exports = {
    getClinics,
    verifyClinicCode,
    getClinicById,
    createClinic,
    updateClinic,
    renewClinic,
    deleteClinic
};
