const admin = require('firebase-admin');

// 1. إعداد Firebase Admin
try {
    if (!admin.apps.length) {
        const serviceAccount = require('../config/firebase.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        console.log("✅ خدمة Firebase Cloud Messaging جاهزة");
    }
} catch (err) {
    console.log("⚠️ ملاحظة: ملف firebase.json مش موجود، التنبيهات رح تظهر بالـ Console بس.");
}

/**
 * إرسال تنبيه احترافي (يدعم الأولوية العالية والبيانات)
 */
const sendNotification = async (token, title, body, data = {}) => {
    console.log(`🔔 محاولة إرسال تنبيه: [${title}] - ${body}`);

    try {
        if (admin.apps.length && token) {
            const message = {
                token: token,
                notification: {
                    title: title,
                    body: body,
                },
                // البيانات الإضافية ضرورية عشان التطبيق يعرف أي طلب يفتح
                data: data, 
                
                // إعدادات الأندرويد لضمان وصول الإشعار فوراً (رنة قوية)
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'high_importance_channel', // لازم تعرفه بكود فلاتر كمان
                        sound: 'default',
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK', // مهم جداً لفتح التطبيق
                    },
                },
                
                // إعدادات آيفون (iOS)
                apns: {
                    payload: {
                        aps: {
                            alert: { title, body },
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            const response = await admin.messaging().send(message);
            console.log("🚀 تم إرسال التنبيه بنجاح للموبايل:", response);
            return response;
        } else {
            console.log("ℹ️ تم الاكتفاء بطباعة التنبيه (التوكن غير موجود أو Firebase غير مفعل)");
            return true;
        }
    } catch (error) {
        console.error('❌ FCM Error:', error.message);
        return false;
    }
};

module.exports = {
    sendNotification,
};