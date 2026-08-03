const Branch = require('../models/Branch');
const Profile = require('../models/Profile');
const Session = require('../models/Session');

// ─────────────────────────────────────────────────────────────
// @desc    Get all branches (filtered by clinic if query param provided)
// @route   GET /api/branches
// @route   GET /api/branches?clinic_id=xxx
// @access  Private
// ─────────────────────────────────────────────────────────────
const getBranches = async (req, res) => {
    try {
        const query = {};

        // If caller passes clinic_id, filter by it; otherwise superadmin gets all
        if (req.query.clinic_id) {
            query.clinic_id = req.query.clinic_id;
        } else if (req.user && req.user.role !== 'superadmin' && req.user.clinic_id) {
            // Non-superadmin users can only see branches in their own clinic
            query.clinic_id = req.user.clinic_id;
        }

        const branches = await Branch.find(query)
            .populate('clinic_id', 'name')
            .sort({ name: 1 });

        res.json(branches);
    } catch (error) {
        console.error('Error fetching branches:', error);
        res.status(500).json({ message: 'Server error fetching branches', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Get single branch by ID
// @route   GET /api/branches/:id
// @access  Private
// ─────────────────────────────────────────────────────────────
const getBranchById = async (req, res) => {
    try {
        const branch = await Branch.findById(req.params.id).populate('clinic_id', 'name');
        if (!branch) {
            return res.status(404).json({ message: 'Branch not found' });
        }
        res.json(branch);
    } catch (error) {
        console.error('Error fetching branch:', error);
        res.status(500).json({ message: 'Server error fetching branch', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Create a new branch under a clinic
// @route   POST /api/branches
// @access  Private (superadmin or clinic admin)
// ─────────────────────────────────────────────────────────────
const createBranch = async (req, res) => {
    try {
        const { name, clinic_id, address, phone, email } = req.body;

        if (!name || !clinic_id) {
            return res.status(400).json({ message: 'Branch name and clinic_id are required' });
        }

        const branch = await Branch.create({ name, clinic_id, address, phone, email });
        const populated = await Branch.findById(branch._id).populate('clinic_id', 'name');

        res.status(201).json(populated);
    } catch (error) {
        console.error('Error creating branch:', error);
        res.status(500).json({ message: 'Server error creating branch', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Update a branch
// @route   PUT /api/branches/:id
// @access  Private (superadmin or clinic admin)
// ─────────────────────────────────────────────────────────────
const updateBranch = async (req, res) => {
    try {
        const updated = await Branch.findByIdAndUpdate(req.params.id, req.body, { new: true })
            .populate('clinic_id', 'name');
        if (!updated) {
            return res.status(404).json({ message: 'Branch not found' });
        }
        res.json(updated);
    } catch (error) {
        console.error('Error updating branch:', error);
        res.status(500).json({ message: 'Server error updating branch', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// @desc    Delete a branch (only if no users / sessions attached)
// @route   DELETE /api/branches/:id
// @access  Private (superadmin only)
// ─────────────────────────────────────────────────────────────
const deleteBranch = async (req, res) => {
    try {
        const branchId = req.params.id;

        // Safety check: do not delete if users are still assigned
        const userCount = await Profile.countDocuments({ branch_id: branchId });
        if (userCount > 0) {
            return res.status(400).json({
                message: `Cannot delete branch. ${userCount} user(s) are still assigned to this branch. Please reassign them first.`
            });
        }

        // Safety check: do not delete if sessions exist
        const sessionCount = await Session.countDocuments({ branch_id: branchId });
        if (sessionCount > 0) {
            return res.status(400).json({
                message: `Cannot delete branch. ${sessionCount} session(s) are still linked to this branch.`
            });
        }

        await Branch.findByIdAndDelete(branchId);
        res.json({ message: 'Branch deleted successfully' });
    } catch (error) {
        console.error('Error deleting branch:', error);
        res.status(500).json({ message: 'Server error deleting branch', error: error.message });
    }
};

module.exports = {
    getBranches,
    getBranchById,
    createBranch,
    updateBranch,
    deleteBranch,
};
