const { Server } = require('socket.io');
const db = require('./config/db');

module.exports = (server) => {
    // إعداد السيرفر مع السماح بالاتصال من الفلتر
    const io = new Server(server, { cors: { origin: "*" } });

    io.on('connection', (socket) => {
        console.log('New client connected:', socket.id);

        // --- ميزة مهمة: انضمام المستخدم لغرفة خاصة به ليصله إشعاراته ---
        // لما الزبون يفتح التطبيق، لازم يعمل emit لـ join_room مع الـ id تاعه
        socket.on('join_room', (userId) => {
            socket.join(`user_${userId}`);
            console.log(`User ${userId} joined their private room`);
        });

        // --- 1. استقبال طلب القبول من السائق ---
        socket.on('accept_order', async ({ orderId, driverId }) => {
            try {
                await db.query('BEGIN');

                // تحديث حالة الطلب والتأكد إنه لسه متاح
                const res = await db.query(`
                    UPDATE orders
                    SET status='ACCEPTED', provider_id=$1, accepted_at=NOW()
                    WHERE id=$2 AND status='SEARCHING' RETURNING *`, [driverId, orderId]);
                
                if (res.rowCount === 0) {
                    socket.emit('order_error', 'الطلب تم قبوله من قبل سائق آخر');
                    await db.query('ROLLBACK');
                    return;
                }

                // زيادة عدد طلبات السائق
                await db.query(`UPDATE users SET active_orders=active_orders+1 WHERE id=$1`, [driverId]);

                // إدارة مجموعات الطلبات (Batch)
                const batchRes = await db.query(`SELECT id FROM batch_groups WHERE provider_id=$1 AND status='ACTIVE'`, [driverId]);
                let batchId;
                if (batchRes.rows.length > 0) {
                    batchId = batchRes.rows[0].id;
                } else {
                    const newBatch = await db.query(`INSERT INTO batch_groups (provider_id) VALUES ($1) RETURNING id`, [driverId]);
                    batchId = newBatch.rows[0].id;
                }

                await db.query(`UPDATE orders SET batch_id=$1 WHERE id=$2`, [batchId, orderId]);
                
                await db.query('COMMIT');

                // جلب بيانات السائق (الاسم، التقييم، التلفون) عشان نعرضهم للزبون
                const driverData = await db.query(`SELECT full_name, rating, phone FROM users WHERE id=$1`, [driverId]);
                
                // أ. تأكيد النجاح للسائق (عشان يشيل الكرت من عنده)
                socket.emit('order_accepted_success', { 
                    orderId: orderId,
                    message: 'تم قبول الطلب بنجاح' 
                });

                // ب. إشعار الزبون (المستخدم) لايف إن السائق قبل الطلب
                // res.rows[0].user_id هو الآيدي تاع الزبون اللي بالداتابيز
                io.to(`user_${res.rows[0].user_id}`).emit('order_accepted_by_driver', {
                    orderId: orderId,
                    status: 'ACCEPTED',
                    driver: {
                        fullName: driverData.rows[0].full_name,
                        phone: driverData.rows[0].phone,
                        rating: driverData.rows[0].rating
                    }
                });

                console.log(`Order ${orderId} accepted by driver ${driverId} for user ${res.rows[0].user_id}`);

            } catch (err) {
                await db.query('ROLLBACK');
                console.error('Accept Order Error:', err);
                socket.emit('order_error', 'حدث خطأ داخلي أثناء قبول الطلب');
            }
        });

        // --- 2. تحديث موقع السائق (Live Tracking) ---
        socket.on('driver:locationUpdate', async ({ driverId, lat, lng }) => {
            try {
                // تحديث موقع السائق في الداتابيز
                await db.query(`UPDATE users SET current_lat=$1, current_lng=$2 WHERE id=$3`, [lat, lng, driverId]);
                
                // جلب كل الطلبات النشطة لهذا السائق لإرسال موقعه للزبائن المعنيين
                const orders = await db.query(`SELECT id, user_id FROM orders WHERE provider_id=$1 AND status IN ('ACCEPTED','ON_ROUTE')`, [driverId]);
                
                for (const order of orders.rows) {
                    // إرسال الإحداثيات لغرفة الزبون
                    io.to(`user_${order.user_id}`).emit('driver:locationUpdate', {
                        orderId: order.id,
                        driverLat: lat,
                        driverLng: lng
                    });
                }
            } catch (err) {
                console.error('Location Update Error:', err);
            }
        });

        socket.on('disconnect', () => {
            console.log('Client disconnected:', socket.id);
        });
    });

    return io;
};