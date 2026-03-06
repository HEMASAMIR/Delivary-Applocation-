const db = require('../config/db');
const matchingService = require('../services/matching.service');
const fcmService = require('../services/fcm.service');

exports.createOrder = async (req, res) => {
    const { userId, orderType, lat, lng, paymentMethod } = req.body;

    try {
        // 1. إنشاء الطلب في قاعدة البيانات (PostgreSQL)
        // ملاحظة: استخدمنا pickup_lat و pickup_lng حسب الجداول الجديدة
        const newOrder = await db.query(
            `INSERT INTO orders (user_id, order_type, pickup_lat, pickup_lng, payment_method, status) 
             VALUES ($1, $2, $3, $4, $5, 'SEARCHING') RETURNING *`,
            [userId, orderType, lat, lng, paymentMethod]
        );

        const order = newOrder.rows[0];

        // 2. البحث عن أقرب سائق
        const driver = await matchingService.findNearestDriver(lat, lng, orderType, 5);

        if (driver) {
            // 3. تحديث الطلب وربطه بالسائق
            await db.query(
                `UPDATE orders SET provider_id = $1, status = 'ACCEPTED' WHERE id = $2`,
                [driver.id, order.id]
            );

            // 4. إرسال تنبيه للسائق عبر FCM
            if (driver.fcm_token) {
                await fcmService.sendNotification(
                    driver.fcm_token,
                    "طلب جديد 🚚",
                    "لديك طلب غاز جديد يبعد عنك مسافة قصيرة"
                );
            }

            return res.status(201).json({
                message: "تم العثور على سائق وقبول الطلب",
                orderId: order.id,
                driver: {
                    id: driver.id,
                    name: driver.full_name,
                    lat: driver.current_lat,
                    lng: driver.current_lng
                }
            });
        } else {
            // 5. في حال عدم وجود سائق
            return res.status(200).json({
                message: "طلبك قيد البحث، لا يوجد سائق متاح حالياً",
                orderId: order.id,
                status: 'SEARCHING'
            });
        }

    } catch (error) {
        console.error('Order Creation Error:', error);
        res.status(500).json({ error: "حدث خطأ أثناء إنشاء الطلب" });
    }
};