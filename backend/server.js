require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const db = require('./config/db'); 

const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET;

const authRoutes = require('./routes/auth.routes');
const ordersRoutes = require('./routes/orders.routes');
const driversRoutes = require('./routes/drivers.routes');

const app = express();
const server = http.createServer(app);

// 1. إعداد Socket.io
const io = new Server(server, {
    cors: {
        origin: "*", 
        methods: ["GET", "POST"]
    },
    connectionStateRecovery: {} 
});

// --- التعديل الجوهري هون يا كبير ---
// هاد السطر بخلينا نقدر ننادي io من جوا أي ملف Route باستخدام req.app.get('socketio')
app.set('socketio', io);

// Middlewares
app.use(cors());
app.use(express.json());

// مسار الفحص
app.get('/', (req, res) => {
    res.json({
        message: '🚀 Gas Delivery Server is Running Live!',
        database_connected: !!db,
        port: PORT
    });
});

// 2. فحص الاتصال بـ PostgreSQL
const checkConnection = async () => {
    try {
        await db.query('SELECT NOW()'); 
        console.log(`✅ يا معلم شبكنا على Supabase بنجاح!`);
    } catch (error) {
        console.error(`❌ صار خطأ بالربط يا كبير: ${error.message}`);
    }
};
checkConnection();

// 3. ربط المسارات (تأكد إنها بتيجي بعد app.set)
app.use('/api/auth', authRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/drivers', driversRoutes);

// 4. منطق السوكت
const users = new Map(); 

io.on('connection', (socket) => {
    console.log('⚡ مستخدم جديد اتصل:', socket.id);

    socket.on('join', (userId) => {
        if (userId) {
            users.set(userId.toString(), socket.id);
            socket.join(`user_${userId}`);
            console.log(`👤 المستخدم ${userId} مرتبط الآن بالسوكت ${socket.id}`);
        }
    });

    socket.on('update_location', (data) => {
        // نبعث الموقع للزبون المتابع للطلب
        io.emit(`driver_location_${data.orderId}`, {
            lat: data.lat,
            lng: data.lng,
            driverId: data.driverId
        });
    });

    socket.on('update_status', (data) => {
        console.log(`📦 تحديث حالة الطلب ${data.order_id} إلى ${data.status}`);
        // إرسال الإشارة للزبون (عبر غرفته الخاصة)
        io.to(`user_${data.user_id}`).emit('status_updated', data);
    });

    socket.on('disconnect', () => {
        for (let [userId, socketId] of users.entries()) {
            if (socketId === socket.id) {
                users.delete(userId);
                break;
            }
        }
        console.log('❌ مستخدم غادر الاتصال');
    });
});

// 5. تشغيل السيرفر
server.listen(PORT, '0.0.0.0', () => { 
    console.log(`🚀 السيرفر شغال بنجاح على بورت: ${PORT}`);
    if(!JWT_SECRET) console.log("⚠️ تحذير: JWT_SECRET مش مقروء من ملف .env");
});