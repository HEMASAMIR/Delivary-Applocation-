const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// تحديث موقع السائق
router.post('/location', auth, async (req,res)=>{
  const { lat, lng } = req.body;
  try {
    await db.query(
      `UPDATE users SET current_lat=$1, current_lng=$2 WHERE id=$3`,
      [lat,lng,req.user.id]
    );
    res.json({ success:true });
  } catch(err){
    res.status(500).json({ error:"خطأ بتحديث الموقع" });
  }
});

// إرجاع كل السائقين النشطين
router.get('/all', auth, async (req,res)=>{
  try {
    const drivers = await db.query(
      `SELECT id, full_name, current_lat AS lat, current_lng AS lng, rating, active_orders
       FROM users WHERE role='PROVIDER' AND status='ACTIVE'`
    );
    res.json(drivers.rows);
  } catch(err){
    res.status(500).json({ error:"خطأ بجلب السائقين" });
  }
});

module.exports = router;