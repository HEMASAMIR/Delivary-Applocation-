const router = require('express').Router();
const bcrypt = require('bcryptjs'); 
const jwt = require('jsonwebtoken');
const db = require('../config/db');

// 1. تسجيل مستخدم جديد (Register)
router.post('/register', async (req, res) => {
    const { phone, password, name, role, vehicleType } = req.body;
    
    try {
        // تشفير كلمة السر
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // إدخال البيانات في جدول users
        const newUser = await db.query(
            `INSERT INTO users (phone, password_hash, full_name, role, vehicle_type) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING id, phone, role, full_name`,
            [phone, hashedPassword, name, role || 'customer', vehicleType]
        );

        // --- التعديل هنا: استخدمنا سر حقيقي من البيئة ---
        const token = jwt.sign(
            { id: newUser.rows[0].id, role: newUser.rows[0].role },
            process.env.JWT_SECRET, // لا تستخدم 'your_secret_key' أبداً في الإنتاج
            { expiresIn: '7d' } // صلاحية التوكن (مثلاً 7 أيام) عشان ما يضطر يسجل دخول كل شوي
        );

        res.status(201).json({ 
            message: "✅ تم التسجيل بنجاح",
            token, 
            user: newUser.rows[0] 
        });

    } catch (err) {
        console.error("Register Error:", err.message);
        // فحص إذا كان الخطأ هو تكرار رقم الهاتف (Unique constraint)
        if (err.code === '23505') {
            return res.status(400).json({ error: "رقم الهاتف هاد مسجل عنا من قبل يا غالي" });
        }
        res.status(500).json({ error: "صار خطأ بالبيانات، تأكد من المدخلات" });
    }
});

// 2. تسجيل الدخول (Login)
router.post('/login', async (req, res) => {
    const { phone, password } = req.body;
    
    try {
        const userRes = await db.query(`SELECT * FROM users WHERE phone = $1`, [phone]);
        
        if (userRes.rows.length === 0) {
            return res.status(400).json({ error: "رقم الهاتف هاد مش موجود عنا يا طيب" });
        }

        const user = userRes.rows[0];

        const match = await bcrypt.compare(password, user.password_hash);
        if (!match) {
            return res.status(400).json({ error: "كلمة السر اللي دخلتها غلط" });
        }

        // --- التعديل هنا: نفس مفتاح التشفير ومدة الصلاحية ---
        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({ 
            message: "✅ نورت الحارة يا معلم",
            token, 
            user: { 
                id: user.id, 
                phone: user.phone, 
                role: user.role, 
                full_name: user.full_name 
            } 
        });

    } catch (err) {
        console.error("Login Error:", err.message);
        res.status(500).json({ error: "خطأ بالخادم، جرب كمان شوي" });
    }
});

module.exports = router;