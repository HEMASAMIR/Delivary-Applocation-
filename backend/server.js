require('dotenv').config(); // سيبحث عن ملف .env وإذا لم يجده سيقرأ من متغيرات النظام مباشرة
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path'); // مطلوب للتعامل مع المجلدات
const db = require('./config/db'); 

const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET;

// استيراد المسارات
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

// إتاحة الوصول لـ Socket.io من داخل الـ Routes
app.set('socketio', io);

// --- Middlewares ---
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // لقراءة بيانات الفورم (Multipart)

// 🔥 أهم تعديل: جعل مجلد الصور متاحاً للجمهور (عشان الخريطة والبروفايل)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// مسار الفحص الأساسي
app.get('/', (req, res) => {
    res.json({
        message: '🚀 Gas Delivery Server is Running Live!',
        database_connected: !!db,
        port: PORT,
        env_status: JWT_SECRET ? "✅ JWT Secret Loaded" : "⚠️ JWT Secret Missing"
    });
});

// 2. فحص الاتصال بـ PostgreSQL
const checkConnection = async () => {
    try {
        await db.query('SELECT NOW()'); 
        console.log(`✅ يا معلم شبكنا على Supabase/PostgreSQL بنجاح!`);
    } catch (error) {
        console.error(`❌ صار خطأ بالربط: ${error.message}`);
    }
};
checkConnection();

// 3. ربط المسارات
// ملاحظة: تأكد أن تطبيق Flutter ينادي /api/auth وليس /api/user
app.use('/api/auth', authRoutes); 
app.use('/api/orders', ordersRoutes);
app.use('/api/drivers', driversRoutes);

// 4. منطق السوكت (Socket.io Logic)
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
        // إرسال الموقع لكل من يتابع الطلب
        io.emit(`driver_location_update`, {
            orderId: data.orderId,
            lat: data.lat,
            lng: data.lng,
            driverId: data.driverId
        });
    });

    socket.on('update_status', (data) => {
        console.log(`📦 تحديث حالة الطلب ${data.order_id} إلى ${data.status}`);
        // إرسال تحديث الحالة لغرفة المستخدم المعني
        io.to(`user_${data.user_id}`).emit('order_update', data);
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
    
    // فحص بيئة العمل
    if(!JWT_SECRET) {
        console.log("❌ خطأ قاتل: JWT_SECRET غير موجود. أضفه في إعدادات الاستضافة!");
    }
});