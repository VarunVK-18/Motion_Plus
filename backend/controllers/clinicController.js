const Clinic = require('../models/Clinic');

// @desc    Get all clinics
// @route   GET /api/clinics
// @access  Public (or Private depending on needs, making it public for signup)
const getClinics = async (req, res) => {
    try {
        const clinics = await Clinic.find({}).sort({ name: 1 });
        res.json(clinics);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Create a new clinic
// @route   POST /api/clinics
// @access  Private
const createClinic = async (req, res) => {
    try {
        const { name, address, phone } = req.body;
        const clinic = await Clinic.create({ name, address, phone });
        res.status(201).json(clinic);
    } catch (error) {
        res.status(500).json({ message: 'Server error creating clinic' });
    }
};

// @desc    Delete a clinic
// @route   DELETE /api/clinics/:id
// @access  Private
const deleteClinic = async (req, res) => {
    try {
        await Clinic.findByIdAndDelete(req.params.id);
        res.json({ message: 'Clinic deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting clinic' });
    }
};

module.exports = {
    getClinics,
    createClinic,
    deleteClinic
};
