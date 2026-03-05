const express = require('express');
const router = express.Router();
const db = require('../config/db');
const auth = require('../middleware/auth'); // الميدل وير الخاص بالـ JWT
const { findNearestDriver } = require('../services/matching.service');
const fcmService = require('../services/fcm.service');

// 1. إنشاء طلب جديد (Create Order)
router.post('/create', auth, async (req, res) => {
    const { orderType, lat, lng, paymentMethod } = req.body;
    const io = req.app.get('socketio'); // سطر ذهبي عشان نستخدم السوكت هون

    try {
        // إضافة الطلب لقاعدة البيانات وحالته المبدئية 'SEARCHING'
        const orderRes = await db.query(
            `INSERT INTO orders (user_id, order_type, pickup_lat, pickup_lng, payment_method, status) 
             VALUES ($1, $2, $3, $4, $5, 'SEARCHING') RETURNING *`,
            [req.user.id, orderType, lat, lng, paymentMethod || 'CASH']
        );

        const newOrder = orderRes.rows[0];

        // إرسال إشعار لكل السائقين القريبين عبر السوكت فوراً
        if (io) {
            io.emit('new_order_available', newOrder);
        }

        // البحث عن أقرب سائق متاح (بقطر 10 كم مثلاً)
        const driver = await findNearestDriver(lat, lng, orderType, 10);

        if (driver) {
            // تحديث الطلب وربطه بالسائق
            await db.query(
                `UPDATE orders SET provider_id = $1, status = 'ACCEPTED' WHERE id = $2`,
                [driver.id, newOrder.id]
            );

            // تحديث حالة الطلب للزبون عبر السوكت (Real-time update)
            if (io) {
                io.to(`user_${req.user.id}`).emit('status_updated', {
                    order_id: newOrder.id,
                    status: 'ACCEPTED',
                    driver: { name: driver.full_name, id: driver.id }
                });
            }

            // إرسال تنبيه للسائق عبر FCM
            if (driver.fcm_token) {
                try {
                    await fcmService.sendNotification(
                        driver.fcm_token,
                        "طلب جديد 🚚",
                        "لديك طلب غاز جديد قريب منك"
                    );
                } catch (fcmErr) {
                    console.error("⚠️ فشل إرسال التنبيه بس الطلب انحجز:", fcmErr.message);
                }
            }

            return res.json({ 
                success: true,
                message: "✅ أبشر، لقينا سواق وقبل الطلب فوراً",
                order: { ...newOrder, status: 'ACCEPTED', provider_id: driver.id }, 
                driver: {
                    id: driver.id,
                    name: driver.full_name,
                    distance: driver.distance
                }
            });
        } else {
            // إذا لم يتوفر سائق حالياً، يضل الطلب SEARCHING
            return res.json({ 
                success: true,
                message: "🔍 طلبك قيد البحث، بنحاول نلاقي لك أقرب سواق حالياً",
                order: newOrder,
                status: 'SEARCHING'
            });
        }

    } catch (err) {
        console.error("❌ Error in /create order:", err.message);
        res.status(500).json({ error: "خطأ بإنشاء الطلب، تأكد من اتصال الداتا بيز" });
    }
});

// 2. إرجاع كل الطلبات النشطة للمستخدم (Get My Orders)
router.get('/my', auth, async (req, res) => {
    try {
        const orders = await db.query(
            `SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC`,
            [req.user.id]
        );
        res.json(orders.rows);
    } catch (err) {
        console.error("❌ Error in /my orders:", err.message);
        res.status(500).json({ error: "خطأ بالخادم أثناء جلب الطلبات" });
    }
});

// 3. عرض الطلبات المتاحة (للسائقين فقط)
router.get('/available', auth, async (req, res) => {
    try {
        const orders = await db.query(
            `SELECT * FROM orders WHERE status = 'SEARCHING' ORDER BY created_at DESC`
        );
        res.json(orders.rows);
    } catch (err) {
        console.error("❌ Error in /available orders:", err.message);
        res.status(500).json({ error: "مش قادرين نجيب الطلبات المتاحة" });
    }
});

module.exports = router;