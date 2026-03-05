const { Pool } = require('pg');
require('dotenv').config();

/**
 * هون التعديل الجوهري:
 * بنخلي الكود يقرأ الرابط من البيئة (process.env) 
 * إذا مش موجود، بنحط الرابط اللي إنت بعته كـ "احتياط" (Backup)
 */
const connectionString = process.env.DATABASE_URL || "postgresql://postgres.ltfrmdkmhvuozraavdiz:Tamerlovers.com123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres?pgbouncer=true";

const pool = new Pool({
    connectionString: connectionString,
    ssl: { 
        rejectUnauthorized: false 
    },
    connectionTimeoutMillis: 30000, 
    idleTimeoutMillis: 30000,
    max: 10 
});

// محاولة الاتصال مع فحص دقيق
pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ فشل الاتصال الأولي يا كبير: ', err.message);
        console.log('---');
        console.log('💡 نصيحة تقنية:');
        console.log('تأكد إنك ضفت DATABASE_URL في الـ Environment Variables على منصة Render.');
        return;
    }
    console.log('✅ أخييييراً.. شبكنا على Supabase يا وحش! وضعك لوز.');
    release(); 
});

module.exports = {
    query: (text, params) => pool.query(text, params),
};