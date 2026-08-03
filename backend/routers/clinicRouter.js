const express = require('express');
const router = express.Router();
const { getClinics, verifyClinicCode, getClinicById, createClinic, updateClinic, renewClinic, deleteClinic } = require('../controllers/clinicController');
const { protect, requireRoles } = require('../middleware/authMiddleware');

// GET  /api/clinics       — public (used for sign-up dropdown)
// POST /api/clinics       — create clinic (superadmin)
router.get('/', getClinics);
router.post('/', protect, requireRoles('superadmin'), createClinic);

// GET /api/clinics/verify/:code
router.get('/verify/:code', verifyClinicCode);

// POST /api/clinics/:id/renew
router.post('/:id/renew', protect, requireRoles('superadmin'), renewClinic);

// GET    /api/clinics/:id — get clinic + its branches
// PUT    /api/clinics/:id — update clinic
// DELETE /api/clinics/:id — delete clinic + cascade branches
router.route('/:id')
    .get(protect, getClinicById)
    .put(protect, requireRoles('superadmin', 'admin'), updateClinic)
    .delete(protect, requireRoles('superadmin'), deleteClinic);

module.exports = router;
