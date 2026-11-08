# sadek-anime-offline — v2

تطبيق Flutter للأنمي، أوفلاين أولاً. **بيانات فقط — لا بث ولا تحميل حلقات.**

Offline-first anime metadata app (Flutter). **Data only — no streaming, no episode downloads.**

## ما الجديد في v2؟ / What's new in v2

- **الفلتر المتقدم (أوفلاين):** من زر الفلتر بجانب البحث تفتح ورقة سفلية (Bottom Sheet) بشرائح: تصنيفات متعددة (افتراضياً "كلها معاً" مع مفتاح للتبديل إلى "أي واحد منها")، نوع، حالة، موسم، شريط سنوات بمقبضين 1980–2026 (أقصى اليسار = "قبل 1980")، تقييم أدنى، عدد حلقات (قصير/متوسط/طويل)، ترتيب، وزر "تطبيق" يعرض عدد النتائج مباشرة. البحث بدون كلمة = تصفح الكل. كل الفلترة على قاعدة SQLite المحلية، فورية وبدون إنترنت.
- **مكتبتي:** تبويب جديد فيه 4 قوائم — مفضلة، أشاهده الآن (مع رقم آخر حلقة وأزرار + / − وشريط تقدم)، سأشاهده، شاهدته. محفوظة في SQLite على الهاتف وتعمل أوفلاين تماماً. تُضاف من صفحة التفاصيل.
- **دخول جوجل + مزامنة Firebase:** زر "تسجيل الدخول بجوجل" في الإعدادات. القوائم تُزامَن إلى Firestore (`users/{uid}/lists`)، والدمج بآخر تعديل (last-write-wins). **بدون Firebase يعمل التطبيق كاملاً محلياً** — تظهر رسالة إعداد واضحة بدل أي خطأ. انظر "إعداد Firebase" أدناه.
- **ثيمات + ثيم مخصص CSS:** 5 ثيمات جاهزة (داكن، فاتح، قرمزي، محيطي، غابة) من الإعدادات، تُطبَّق فوراً. وخيار "ثيم مخصص (CSS)": الصق متغيرات CSS وستُطبَّق فوراً وتُحفظ، مثال:
  ```css
  --bg: #0F1015;
  --surface: #181A22;
  --surface-hi: #22252F;
  --accent: #6366F1;
  --accent2: #8B5CF6;
  --text: #FFFFFF;
  --text-dim: #9CA3AF;
  --star: #FBBF24;
  ```
  المتغيرات المعروفة: `--bg`, `--surface`, `--surface-hi`, `--accent`, `--accent2`, `--text`, `--text-dim`, `--star`. أي متغير ناقص أو غير صالح يبقى على قيمة الثيم الأساسي.
- **أيقونة جديدة:** وجه الأنمي بخطوط بيضاء على خلفية داكنة `#0F1015` (النسخة الداكنة من رسمة المستخدم، `assets/icon/icon_dark.png`)، مع النسخة البيضاء الأصلية `assets/icon/icon.png`. أيقونات Android (mipmap + adaptive icon) تُحقن في البناء.
- **كل القصص محمّلة في الـ DB:** وقت البناء في CI تُجلب القصة **الإنجليزية لكل العناوين** من AniList (دفعات 50 عنواناً في الطلب) وتُحفظ في `anime.db`، فتظهر فوراً بدون إنترنت وبدون فتح كل أنمي أول مرة. القصة **العربية** تُجلب من TMDB أثناء البناء أيضاً عندما يكون مفتاح `TMDB_API_KEY` موجوداً — **لكن العربي يغطي فقط الأعمال التي لها ملخص عربي في TMDB (المعروفة غالباً)**، وليس كل الأعمال؛ الباقي يظهر بالإنجليزية مع تنبيه. الجلب عند فتح الأنمي (Jikan/AniList) يبقى كبديل احتياطي فقط.

## كيف يعمل؟ / How it works

- **Data:** SQLite DB built in CI from manami-project/anime-offline-database (titles, type, episodes, status, season, score, tags, studios, poster URL) + synopses preloaded (see above).
- **Synopsis / characters:** English synopsis is now in the DB. Characters are still fetched on demand from Jikan the first time you open a title (AniList as backup), then cached in SQLite.
- **Posters:** loaded as WebP on demand, cached on disk.
- **Search:** indexed local search (multi-word), instant; falls back to Jikan if < 5 local hits.

## بناء الـ APK / Build the APK

Push to `main`/`master` (or run the workflow manually) → GitHub → Actions → latest run → Artifacts → `sadek-anime-offline-apk`.

**مهم — أول تثبيت لـ v2:** احذف التطبيق القديم من الهاتف (أو امسح بياناته) قبل تثبيت v2، لأن مخطط قاعدة البيانات تغيّر (جدول `user_lists` جديد + قصص محمّلة مسبقاً)، وإلا قد تبقى قاعدة البيانات القديمة بدون القصص والقوائم.

## الرفع من Termux / Upload from Termux

```bash
cd ~
rm -rf sadek-anime-offline && mkdir sadek-anime-offline
# فك ملف sadek-anime-offline-v2.zip هنا (أو انسخ مجلد المشروع)
cd sadek-anime-offline
git init -b main
git add .
git commit -m "v2: filter, library, Firebase sync, themes, icon, preloaded synopses"
git remote add origin https://github.com/sadekch1/sadek-anime-offline.git
git push -u origin main --force
```

إذا كان المستودع موجوداً أصلاً وفيه التاريخ القديم، استخدم بدلاً من ذلك نسخة موجودة واستبدل ملفاتها ثم `git add . && git commit -m "v2 ..." && git push` (وإذا رفض الدفع: `git pull --rebase origin main` ثم أعد الدفع).

بعد الدفع: GitHub → Actions → انتظر اكتمال التشغيل (قد يطول إلى 20–30 دقيقة بسبب تحميل القصص) → Artifacts → `sadek-anime-offline-apk` → فك الـ zip وثبّت `app-release.apk`.

## التشغيل محلياً / Local run

```
python tools/build_db.py
flutter create --platforms=android --org com.sadek --project-name sadek_anime_offline .
flutter pub get && flutter run
```

(Add `<uses-permission android:name="android.permission.INTERNET"/>` to the main AndroidManifest for release builds — CI does this automatically.)

## الدعم العربي / Arabic support

UI is fully hand-translated (ar/en, RTL). Story text in Arabic comes from **TMDB** community-written overviews (not machine translation).

1. Create a free key at themoviedb.org → Settings → API.
2. Either add it as a GitHub secret `TMDB_API_KEY` (used at build time to preload Arabic synopses, and baked into the APK), or paste it in the app's Settings.
Titles without an Arabic overview on TMDB show the English synopsis with a notice.

## إعداد Firebase (مرة واحدة، اختياري) / Firebase setup (once, optional)

بدون هذه الخطوات يعمل التطبيق كاملاً محلياً، والمزامنة فقط هي التي لا تعمل.

1. **مفتاح توقيع ثابت (مهم):** أنشئ keystore واحداً مرة واحدة في Termux ولا تغيّره أبداً، وإلا لن يتحدث التطبيق فوق القديم وسيتعطل دخول جوجل:
   ```bash
   keytool -genkeypair -v -keystore release.keystore -alias sadek -keyalg RSA -keysize 2048 -validity 10000
   keytool -list -v -keystore release.keystore   # انسخ بصمة SHA-1 من هنا
   base64 -w0 release.keystore   # الصق الناتج كسر KEYSTORE_BASE64 في GitHub
   ```
   أضف أسرار GitHub: `KEYSTORE_BASE64` (ناتج base64)، `KEYSTORE_PASSWORD`، `KEY_PASSWORD`، `KEY_ALIAS` (مثال: `sadek`). بدونها يبني الـ workflow بمفتاح debug.
2. **مشروع Firebase:** في console.firebase.google.com أنشئ مشروعاً، فعّل Authentication ← Google provider، وفعّل Firestore (وضع الإنتاج).
3. **أضف تطبيق Android:** اسم الحزمة هو `com.sadek.sadek_anime_offline` (الناتج من `--org com.sadek --project-name sadek_anime_offline`) — سجّل هذا الاسم بالظبط، والصق بصمة SHA-1 من الخطوة 1.
4. **قواعد Firestore** (Firestore ← Rules):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
5. **سر GitHub:** نزّل `google-services.json` من Firebase وأضفه كسر باسم `GOOGLE_SERVICES_JSON` (محتوى الملف كاملاً). الـ workflow يستخرج منه مفاتيح Firebase ويمررها للبناء كـ dart-define؛ **لا ترفع الملف نفسه إلى المستودع**. بدون السر يبني التطبيق بدون مزامنة.
6. بعد إضافة السر، شغّل الـ workflow يدوياً من Actions ← Run workflow، ثم سجّل الدخول بجوجل من الإعدادات في التطبيق.
