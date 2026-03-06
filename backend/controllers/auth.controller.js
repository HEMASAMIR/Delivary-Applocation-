const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// 1. دالة التسجيل (Signup)
exports.register = async (req, res) => {
    const { full_name, email, password, phone, role } = req.body;

    try {
        const userExist = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userExist.rows.length > 0) {
            return res.status(400).json({ message: "الإيميل هاد مستخدم يا غالي، جرب غيره" });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = await db.query(
            'INSERT INTO users (full_name, email, password, phone, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, full_name, email, role',
            [full_name, email, hashedPassword, phone, role || 'customer']
        );

        const user = newUser.rows[0];

        // --- التعديل هون: بنعمل توكن فوراً عشان يدخل عالتطبيق مباشرة ---
        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET || 'secret_key_123',
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: "✅ تم التسجيل بنجاح يا معلم",
            token, // نبعث التوكن هون كمان
            user: user
        });

    } catch (error) {
        console.error(error.message);
        res.status(500).json({ message: "صار خطأ بالسيرفر يا كبير" });
    }
};

// 2. دالة تسجيل الدخول (Login) - الكود تبعك ممتاز زي ما هو
exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const userResult = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
            return res.status(400).json({ message: "الإيميل أو الباسوورد غلط يا حبيب" });
        }

        const user = userResult.rows[0];

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "الإيميل أو الباسوورد غلط يا حبيب" });
        }

        // إنشاء Token (JWT) - بقرأ من الـ .env صح ✅
        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET || 'secret_key_123',
            { expiresIn: '7d' }
        );

        res.json({
            message: "✅ نورت الحارة، دخلت بنجاح",
            token,
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error(error.message);
        res.status(500).json({ message: "صار خطأ بالسيرفر يا كبير" });
    }
};