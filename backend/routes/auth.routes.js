const router = require('express').Router();
const bcrypt = require('bcryptjs'); 
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const multer = require('multer');
const path = require('path');

// --- إعداد تخزين الصور (Multer Setup) ---
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/profiles/');
    },
    filename: (req, file, cb) => {
        // اسم ملف فريد: profile-timestamp.jpg
        cb(null, 'profile-' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 2 * 1024 * 1024 }, // حد أقصى 2 ميجا بايت
});

// 1. تسجيل مستخدم جديد (Register)
router.post('/register', async (req, res) => {
    const { phone, password, name, role, vehicleType } = req.body;
    
    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = await db.query(
            `INSERT INTO users (phone, password_hash, full_name, role, vehicle_type) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING id, phone, role, full_name`,
            [phone, hashedPassword, name, role || 'customer', vehicleType]
        );

        const token = jwt.sign(
            { id: newUser.rows[0].id, role: newUser.rows[0].role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({ 
            message: "✅ تم التسجيل بنجاح",
            token, 
            user: newUser.rows[0] 
        });

    } catch (err) {
        console.error("Register Error:", err.message);
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
                full_name: user.full_name,
                address: user.address,
                profile_image: user.profile_image 
            } 
        });

    } catch (err) {
        console.error("Login Error:", err.message);
        res.status(500).json({ error: "خطأ بالخادم، جرب كمان شوي" });
    }
});

// 3. تحديث الملف الشخصي (Update Profile)
// نستخدم upload.single('image') لأن الفلاتر سيرسل ملفاً باسم 'image'
router.post('/update-profile', upload.single('image'), async (req, res) => {
    const { name, address, password, userId } = req.body; 
    let profileImagePath = null;

    // إذا تم رفع ملف، نحفظ مساره
    if (req.file) {
        profileImagePath = `/uploads/profiles/${req.file.filename}`;
    }

    try {
        // بناء الاستعلام بشكل ديناميكي
        let query = "UPDATE users SET full_name = $1, address = $2";
        let params = [name, address];
        let paramCount = 2;

        // تحديث الصورة إذا وجدت
        if (profileImagePath) {
            paramCount++;
            query += `, profile_image = $${paramCount}`;
            params.push(profileImagePath);
        }

        // تحديث كلمة السر إذا وجدت
        if (password && password.length >= 6) {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            paramCount++;
            query += `, password_hash = $${paramCount}`;
            params.push(hashedPassword);
        }

        // تحديد المستخدم المراد تحديثه
        paramCount++;
        query += ` WHERE id = $${paramCount}`;
        params.push(userId);

        const updatedUser = await db.query(
            `${query} RETURNING id, phone, role, full_name, address, profile_image`,
            params
        );

        if (updatedUser.rows.length === 0) {
            return res.status(404).json({ error: "المستخدم غير موجود" });
        }

        res.json({ 
            message: "✅ تم تحديث بياناتك بنجاح",
            user: updatedUser.rows[0] 
        });

    } catch (err) {
        console.error("Update Profile Error:", err.message);
        res.status(500).json({ error: "فشل تحديث البيانات في السيرفر" });
    }
});

module.exports = router;