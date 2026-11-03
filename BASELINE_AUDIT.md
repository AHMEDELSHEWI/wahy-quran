# BASELINE_AUDIT — وحي (Phase 0)

تاريخ التدقيق: 2026-10-31 · الفرع: `claude/ultimate-web-scraper-phase-0-4xz97l` · HEAD قبل هذا التقرير: `062b319`

هذا التقرير يصف الحالة **كما وجدتها**، قبل أي تعديل على كود التطبيق. كل رقم هنا قابل لإعادة الإنتاج بـ
`python3 scripts/phase0/phase0_audit.py .` والسجلات في `evidence/phase0/`.

## 1. الخلاصة

- المستودع **ليس من الصفر**: يحوي تطبيق Flutter بحوالي 1045 سطر Dart، وقاعدة بيانات بها 6236 آية، و604 صفحة مصحف مصوّرة.
- `flutter analyze` ينجح (لا توجد أخطاء تحليل)، لكن **لا توجد أي اختبارات** (`test/` غير موجود) و**لم يُبنَ APK** في هذه البيئة لعدم وجود Android SDK.
- README يصرّح بنفسه أن الكود «لم يُبنَ أو يُشغَّل فعليًا». تم الآن تشغيل التحليل والتنسيق والاختبار، لكن لم يُشغَّل التطبيق على أي جهاز أو محاكٍ.
- **مشكلة بيانات جوهرية:** ملف `ayat_multi` يحوي أربع قراءات غير حفص (ورش، قالون، الدوري، شعبة) بلا أي سجل مصدر، وبعضها بقيم صفحات تالفة. والواجهة تعرضها للمستخدم كاختيارات قابلة للتحديد. هذا يخالف القاعدة «لا تعلن دعم القراءات قبل وجود fixtures ومصادر واختبارات».
- **مصادر أساسية من الـPrompt غير موجودة** في البيئة: ملفات PDF لمصحف الكويت (629 صفحة) وملف `GOLDEN MASTER PROMPT.docx` وقاعدة كلمات «نون». التفاصيل في `KNOWN_BLOCKERS.md`.

## 2. البيئة (Inventory)

| المكوّن | القيمة | الحالة |
|---|---|---|
| نظام التشغيل | Ubuntu 24.04.5 LTS، kernel 6.18 | ✅ |
| Git | 2.43.0 | ✅ |
| Flutter | 3.24.0 stable (rev 80c2e84975)، ثبّتتُه من `storage.googleapis.com`، SHA-256 مطابق لـ`releases_linux.json` | ✅ مثبت خارج المستودع في `/root/sdk/flutter` |
| Dart | 3.5.0 (مرفق مع Flutter 3.24.0) | ✅ |
| Java | OpenJDK 21.0.12 | ✅ |
| Gradle | 8.14.3 في `/opt/gradle-8.14.3` | ✅ (المشروع يستخدم wrapper 8.3، غير مختبر) |
| Kotlin | 2.0.21 (بحسب خرج Gradle) | ✅ لكن `android/settings.gradle` يثبّت Kotlin 1.9.10 |
| Node / npm | 22.23.4 / 10.9.9 | ✅ (غير مستخدم في التطبيق) |
| Python | 3.13.18 | ✅ |
| Chrome | Chrome for Testing 153 | ✅ |
| Android SDK / NDK / sdkmanager / adb | غير مثبتة | ❌ |
| `dl.google.com` | HTTP 000 (غير قابل للوصول) | ❌ يمنع تثبيت Android SDK |
| GTK 3 dev | غير مثبت | ⚠️ لا يلزم للهدف Android |

ملاحظة: `flutter doctor` يُبلّغ عن ✗ للـAndroid toolchain وLinux toolchain و⚠ لـAndroid Studio. هذه النتائج متوقعة في البيئة.

## 3. حالة المستودع (Repository)

- الفرع الحالي: `claude/ultimate-web-scraper-phase-0-4xz97l`. الفروع الأخرى: `main`.
- عدد الملفات المتتبعة: 632 (منها 604 صورة مصحف بحجم إجمالي 128 MB).
- الـremote: `https://github.com/AHMEDELSHEWI/wahy-quran`.
- الشجرة قبل هذا التقرير نظيفة (`git status` فارغ).
- سجل Git يحوي حذف وإعادة رفع لـ`assets/db/quran.db` (commits `cf344f0` و`062b319`)، وحذف `assets/db/1440`. الحجم الحالي 11,042,816 بايت، بينما README وarchitecture.md يذكران 2.1 MB. **هذا تناقض توثيقي.**
- الملفات المحلية `android/local.properties` متتبعة وتشير إلى `/opt/hostedtoolcache/flutter/stable` (غير موجود هنا). هذا ملف خاص بالجهاز ولا يجب تتبعه.
- `.github/workflows/flutter-ci.yml` يعمل على `main`/`master` فقط ولا يعمل على هذا الفرع. يستخدم Flutter 3.24.0 (يطابق تثبيتي). خطوات `dart format` و`flutter test` بـ`continue-on-error`، أي أن CI لا يفشل حتى لو فشلا.
- `README.md` يشير إلى `docs/data-model.md` والملف فعليًا في الجذر `data-model.md`.

## 4. التطبيق (Code baseline)

| الملف/المنطقة | الملاحظة |
|---|---|
| `pubspec.yaml` | `sqflite ^2.3.3+1` (مُحلّ إلى 2.4.1)، `path_provider ^2.1.4`، `flutter_lints ^4.0.0` (لكن لا يوجد `analysis_options.yaml` يفعّله). |
| `lib/main.dart` | حالة القراءة المختارة (`_selectedQiraat`) في الـwidget الجذر فقط، **غير محفوظة** بين الجلسات. |
| `lib/db/quran_database.dart` | ينسخ `quran.db` إلى مجلد المستندات **فقط إذا لم يكن موجودًا**. لا يوجد فحص نسخة (version) ⇒ أي تحديث لاحق لقاعدة الأصول **لن يصل** للمستخدمين الحاليين. الدالة `searchAyat` تستخدم `LIKE` على النص المشكّل، و`catch` عام يبتلع الأخطاء ويرجع لجدول قديم. |
| `getAvailableQiraat()` | إذا فشل الاستعلام تُعاد قائمة افتراضية بحفص فقط، فيختفي الخطأ بصمت. |
| `lib/screens/qiraat_picker_screen.dart` | يعرض القراءات الخمس من جدول `qiraat` كاختيارات قابلة للتحديد: حفص، ورش، قالون، الدوري، شعبة. |
| `lib/screens/mushaf_viewer_screen.dart` | يعرض صور الصفحات 1–604 مباشرة. تعليقه يقول «مع tajweed color-coding كامل» وهو ادعاء غير موثّق. |
| `lib/screens/about_screen.dart` | يعرض أن النص «مستورد آليًا… لم يخضع بعد لمراجعة علمية» ✅ صادق. |
| `lib/screens/surah_screen.dart` | يعرض حالة التحقق للآية ✅. |
| الاختبارات | لا يوجد مجلد `test/`. الصفر اختبار. |
| الإخراج الثابت | `dart analyze` لا يتضمن قواعد إضافية. لا توجد قواعد lint مخصصة. |

## 5. نتائج الـBaseline (أوامر منفّذة فعليًا)

التنفيذ على تصدير نظيف لـ`HEAD` (`git archive`) في `/root/baseline` لعدم تعديل شجرة العمل.

| الأمر | النتيجة | السجل |
|---|---|---|
| `flutter pub get` | exit 0. تغيّرت 44 تبعية، و37 لها إصدارات أحدث غير متوافقة مع القيود. | (مخرج في الجلسة) |
| `flutter analyze` | exit 0، **«No issues found! (ran in 26.4s)»** | `evidence/phase0/flutter_analyze.log` |
| `dart format --set-exit-if-changed lib` | exit 1. يحتاج تنسيق: `lib/models/surah.dart` و`lib/screens/surah_screen.dart` | `evidence/phase0/dart_format.txt` |
| `flutter test` | exit 1: «Test directory "test" not found». **عدد الاختبارات: 0.** | `evidence/phase0/flutter_test.log` |
| `flutter build apk --debug` | **لم يُنفَّذ (BLOCKED):** Android SDK غير موجود و`dl.google.com` غير قابل للوصول | انظر KNOWN_BLOCKERS.md |
| تشغيل على جهاز/محاكٍ | **لم يُنفَّذ (UNEXECUTED)** | — |
| `flutter build linux` | لم يُنفَّذ: لا يلزم للهدف، وsqflite لا يدعم Linux desktop أصلًا | — |

## 6. نتائج فحص البيانات (Data baseline)

التفاصيل الكاملة في `evidence/phase0/db_audit.json` و`image_audit.json`.

| الفحص | النتيجة |
|---|---|
| SHA-256 للقاعدة | `3afad63e5bb23a75102275ec4f933578758a0f560af5f1b54613c4c084a1accd` |
| جدول `surahs` | 114 صفًا ✅ |
| جدول `ayat` (حفص، من Tanzil) | 6236 صفًا، `riwayah=hafs_an_asim`، كلها `auto_imported_pending_scholar_review` ✅ عدديًا |
| `data_provenance` | **صف واحد فقط** (Tanzil). لا توجد أي سجلات مصدر لبقية الجداول |
| `ayat_multi` | 31,117 صفًا، خمس قيم `qiraat_id`: hafs (6236)، shouba (6236)، warsh (6214)، qaloon (6214)، doori (6217) |
| `ayat_multi` بقيم صفحات غير صحيحة | **13 صفًا**: warsh (4)، qaloon (4)، doori (5). أمثلة: `'85-86'`، `'317-318'`، `'354-355'` في عمود `page`/`line_start` |
| حفص `ayat_multi` مقابل جدول `ayat` بعد إزالة التشكيل | تطابق 6235 من 6236. **آية واحدة (2:72) تختلف** بعد إزالة التشكيل أيضًا، لم أفحصها حرفًا بحرف بعد (مفتوح) |
| حفص `ayat_multi` مقابل `ayat` بالتشكيل | **1141 آية تختلف في التشكيل فقط** (قيمة `hafs_vs_ayat_exact_mismatch_count`، بعد إزالة رقم الآية الملحق) |
| صفحات حفص | 604 صفحة، من 1 إلى 604، بلا فجوات، وبترتيب تصاعدي ✅ |
| صور المصحف | 604 صورة من 1.jpg إلى 604.jpg، لا ناقص ولا زائد، **بلا تكرار محتوى** ✅ |
| أبعاد الصور | 602 صورة بـ645×1000، و**صفحتان فقط** (1 و2) بـ486×738 ⚠️ |
| تحقق بصري من الصور | الصفحة 1: الفاتحة 1:1–1:7 ✅ (تطابق DB). الصفحة 3: تبدأ بـ2:6 «إِنَّ الَّذِينَ كَفَرُوا» ✅ (تطابق DB). الصور تحوي ألوان تجويد وlegend، ولم يُتحقق من ترميزها بمصدر. |
| تحقق من الآيات عبر Shamela (مكتبة محلية، ليست مرجعًا نهائيًا) | 1:7 ✅ مطابق. 2:1 ✅ «الم». 2:72: نسخة majma تحوي الشدة على «مَّا»، فجدول `ayat` صحيح هنا وجدول `ayat_multi` ناقص. |

### 6.1 تفسير نتائج القراءات غير حفص (مهم)

- **شعبة (shouba):** 5652 آية متطابقة حرفيًا مع حفص، و6142 بعد إزالة التشكيل. هذا نمط يتوافق مع اختلافات تشكيل محدودة، **لكن لا يمكن التحقق منه من هذه البيئة** لعدم توفر مصدر مرجعي.
- **ورش وقالون:** التطابق مع حفص ضعيف (14 و26 حرفيًا، 663 و672 بعد إزالة التشكيل). هذا قد يكون اختلافًا حقيقيًا بين الروايات، وقد يكون ناتجًا عن ترميز مختلف. **لا يمكن الحكم** دون مصدر مرجعي.
- **ورش وقالون بـ6214 آية** (أقل من 6236 بـ22). هذا يطابق عدد آيات العد المدني **كفرضية** (لم تُتحقق)، ويعني أن ترقيم `ayah_number` في هذه الروايات **لا يطابق ترقيم حفص**. الواجهة تستخدم `surah_id + ayah_number` لكل الروايات، فهذا خطأ تصميمي محتمل.
- **قالون وورش متطابقان حرفيًا في 1297 صفًا:** قد يكون ذلك صحيحًا في بعض المواضع، لكنه يستدعي التحقق.
- **الدوري:** 634 حرفيًا مع حفص، 775 بعد إزالة التشكيل، وقيم صفحات تالفة.

**النتيجة:** لا يوجد أي دليل على أن نصوص القراءات الأربع صحيحة، ولا أي دليل على أنها خاطئة. الحالة الصحيحة لها هي **UNVERIFIED / NOT_IMPLEMENTED**، ولا تُعرض للمستخدم كقراءة مدعومة.

## 7. الوضع الحالي مقابل متطلبات الـPrompt (ملخص)

التفصيل في `REQUIREMENTS_MATRIX.csv`. الخلاصة:

- **موجود ويعمل عدديًا:** عرض المصحف بالصور، تصفح السور، بحث نصي بسيط، شاشة مصدر، عمل offline (لا استدعاءات شبكة).
- **موجود لكنه يدّعي أكثر من دليله:** دعم خمس قراءات، «tajweed color-coding» في المصحف.
- **غير موجود:** الاختبارات، جداول Page Mapping، سجلات provenance لكل مجموعة، نموذج بيانات القراءات الهرمي، محرك التلاوة (VAD، ASR، alignment)، أي اختبار على جهاز، APK.

## 8. ما لم يُنفَّذ وسببه

- بناء APK / AAB: **BLOCKED** — لا Android SDK، و`dl.google.com` غير قابل للوصول.
- تشغيل التطبيق على جهاز أو محاكٍ: **UNEXECUTED** — نفس السبب.
- التحقق من نص حفص مقابل Tanzil الرسمي: **BLOCKED** — `tanzil.net` غير قابل للوصول (HTTP 000).
- التحقق من الصفحات مقابل مصحف المدينة 1405 أو مصحف الكويت: **BLOCKED** — مصحف الكويت غير موجود في البيئة.

## 9. الأدلة

- `evidence/phase0/flutter_analyze.log`
- `evidence/phase0/flutter_test.log`
- `evidence/phase0/dart_format.txt`
- `evidence/phase0/toolchain.txt`
- `evidence/phase0/db_audit.json`
- `evidence/phase0/image_audit.json`
- `scripts/phase0/phase0_audit.py` (يعيد توليد كل ما سبق من المستودع)
- `PAGE_MAPPING.csv` (604 صفًا)
- `SOURCE_MANIFEST.json`
