# ملاحظات نشر ممثلي على Render

تؤكد وثائق Render الرسمية أن خدمة Web Service يمكن ربطها بمستودع GitHub، وأن كل push إلى الفرع المرتبط يمكن أن يطلق build وdeploy تلقائياً. في مشروع Node/Express يمكن استخدام أوامر المشروع نفسها؛ لهذا المشروع الأمر المقترح للبناء هو `pnpm install --frozen-lockfile && pnpm build`، وأمر التشغيل هو `pnpm start`. يجب أن يستمع التطبيق على `0.0.0.0` ويستخدم متغير `PORT`، وهو ما يفعله الخادم الحالي.

مصدر Render: https://render.com/docs/deploy-node-express-app
مصدر Render لخدمات الويب ومتغيرات البيئة وفحص الصحة: https://render.com/docs/web-services

يحتاج Render إلى متغيرات البيئة في Advanced → Environment Variables. يجب وضع مفاتيح الخادم السرية هناك، ولا توضع في GitHub. في تطبيق ممثلي يمكن وضع `SUPABASE_URL` و`SUPABASE_ANON_KEY` كإعداد عام آمن، بينما يبقى `SUPABASE_KEY` من نوع `sb_secret` خادمياً فقط إذا احتاجت وظائف خلفية إلى صلاحيات مرتفعة. مسار الصحة الحالي هو `/api/health`.

مصدر Supabase للمفاتيح: https://supabase.com/docs/guides/api/api-keys
توضح الوثيقة أن publishable key يصلح للمتصفح وتخضع طلباته لـ RLS، أما secret key فيتجاوز RLS ويجب ألا يغادر الخادم أو يدخل الكود المنشور.

مصدر Supabase لمصادقة الهاتف: https://supabase.com/docs/guides/auth/phone-login
يجب تفعيل Phone Auth ومزود SMS في Supabase قبل استخدام تدفق التحقق برقم الهاتف. النسخة الحالية تستخدم signInWithPassword برقم الهاتف، ويجب تأكيد إعدادات Phone Auth في المشروع قبل اختبار التسجيل الحقيقي.
