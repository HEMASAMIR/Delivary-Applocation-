const db = require('../config/db');

/**
 * البحث عن أقرب سائق متاح باستخدام الحسابات الجغرافية (Haversine Formula)
 */
exports.findNearestDriver = async (orderLat, orderLng, orderType, radiusKm = 10) => {
    try {
        // الاستعلام المدمج: يحسب المسافة بين نقطتين
        const query = `
            SELECT id, full_name, fcm_token, current_lat, current_lng,
            (
                6371 * acos (
                    LEAST(1.0, GREATEST(-1.0, 
                        cos( radians($1) )
                        * cos( radians( current_lat ) )
                        * cos( radians( current_lng ) - radians($2) )
                        + sin( radians($1) )
                        * sin( radians( current_lat ) )
                    ))
                )
            ) AS distance
            FROM users
            WHERE role = 'DRIVER' -- تأكدت إنها DRIVER زي ما عملناها بالـ Auth
              AND status = 'ACTIVE' 
              AND (current_lat IS NOT NULL AND current_lng IS NOT NULL)
            -- شلنا شرط vehicle_type إذا كنت بدك كل السائقين يوصلهم، 
            -- أو رجعه إذا كان عندك أنواع سيارات مختلفة (غاز، بنزين، الخ)
            GROUP BY id, full_name, fcm_token, current_lat, current_lng
            HAVING (
                6371 * acos (
                    LEAST(1.0, GREATEST(-1.0, 
                        cos( radians($1) )
                        * cos( radians( current_lat ) )
                        * cos( radians( current_lng ) - radians($2) )
                        + sin( radians($1) )
                        * sin( radians( current_lat ) )
                    ))
                )
            ) <= $3
            ORDER BY distance ASC
            LIMIT 1;
        `;

        // لاحظ شلنا orderType من الباراميترز مؤقتاً للتأكد من الشغل، رجعه لو عندك أنواع مركبات
        const result = await db.query(query, [orderLat, orderLng, radiusKm]);

        if (result.rows.length === 0) {
            console.log("⚠️ لا يوجد سائقين متاحين حالياً في هذا النطاق");
            return null;
        }

        const nearestDriver = result.rows[0];
        console.log(`✅ تم العثور على: ${nearestDriver.full_name} على بعد ${parseFloat(nearestDriver.distance).toFixed(2)} كم`);
        
        return nearestDriver;

    } catch (error) {
        console.error('❌ خطأ في عملية مطابقة السائقين:', error.message);
        // Fallback: جلب أي سائق نشط في حال فشل الحساب المعقد
        try {
            const fallbackResult = await db.query(
                `SELECT id, full_name, fcm_token FROM users WHERE role = 'DRIVER' AND status = 'ACTIVE' LIMIT 1`
            );
            return fallbackResult.rows[0] || null;
        } catch (fallbackErr) {
            return null;
        }
    }
};