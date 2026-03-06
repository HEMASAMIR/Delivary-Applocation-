const jwt = require('jsonwebtoken');
require('dotenv').config(); // عشان يسحب المفتاح السري من الـ .env

module.exports = (req, res, next) => {
    // 1. جلب التوكن بطريقة مرنة (بتدعم Bearer TOKEN أو التوكن المباشر)
    const authHeader = req.headers['authorization'] || req.header('Authorization');
    const token = authHeader?.split(' ')[1] || authHeader?.replace('Bearer ', '');

    // 2. إذا ما في توكن أصلاً، بنسكر الباب ونحكي له سجل دخول
    if (!token) {
        return res.status(401).json({ 
            error: "يا غالي ما معك صلاحية، سجل دخول أول (Missing Token)" 
        });
    }

    try {
        // 3. التحقق من التوكن باستخدام المفتاح السري
        // حطينا 'your_secret_key' كاحتياط عشان السيرفر ما يوقف إذا الـ .env مش مقروء
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
        
        // 4. تخزين بيانات المستخدم (id, role) جوا الـ req عشان الـ Routes يستخدموها
        req.user = decoded;
        
        // 5. مسموح له يمر للمرحلة الجاية (الـ Controller)
        next();
    } catch (err) {
        // 6. إذا التوكن منتهي أو فيه مشكلة
        console.error("JWT Auth Error:", err.message);
        return res.status(401).json({ 
            error: "التوكن تبعك منتهي أو غلط، ارجع سجل دخول يا كبير" 
        });
    }
};