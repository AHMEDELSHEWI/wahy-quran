# نموذج البيانات — منصة وحي

## الجداول الحالية (Foundation Release)

### `surahs`
| العمود | النوع | الوصف |
|---|---|---|
| id | INTEGER PK | رقم السورة (1-114) |
| name_ar | TEXT | اسم السورة بالعربية |
| name_transliteration | TEXT | الاسم بالحروف اللاتينية |
| revelation_type | TEXT | meccan / medinan |
| total_ayat | INTEGER | عدد الآيات |

### `ayat`
| العمود | النوع | الوصف |
|---|---|---|
| id | INTEGER PK AUTOINCREMENT | معرف داخلي |
| surah_id | INTEGER FK | يشير إلى surahs.id |
| ayah_number | INTEGER | رقم الآية داخل السورة |
| text_uthmani | TEXT | النص بالرسم العثماني |
| riwayah | TEXT | الرواية (افتراضي: hafs_an_asim) |
| source_primary | TEXT | المصدر الأساسي (tanzil_uthmani) |
| source_rasm_reference | TEXT | مرجع الرسم (madinah_mushaf_1405h) |
| verification_status | TEXT | حالة التحقق العلمي |

### `data_provenance`
سجل واحد لكل مجموعة بيانات مستوردة: المصدر، الرابط، الرخصة، تاريخ الاستيراد،
ملاحظة التحقق. يُقرأ ويُعرض للمستخدم في شاشة "حول المصدر والتوثيق" — شفافية
مباشرة تجاه المستخدم بدل إخفاء أصل البيانات.

---

## توسعات مستقبلية مقترحة (غير مبنية بعد)

هذه الجداول **غير موجودة حاليًا** في قاعدة البيانات، وتحتاج تصميمًا وتحققًا
علميًا كاملاً قبل إضافتها فعليًا (تماشيًا مع القسم 9-13 من المستند الأصلي):

```sql
-- روايات وقراءات إضافية
CREATE TABLE qiraat (
    id INTEGER PRIMARY KEY,
    name_ar TEXT,
    reciter_chain TEXT,  -- سند القراءة
    tariq TEXT           -- الطريق
);

-- ربط كل آية بنص مختلف حسب الرواية (بدل عمود riwayah الواحد الحالي)
CREATE TABLE ayat_variants (
    id INTEGER PRIMARY KEY,
    surah_id INTEGER,
    ayah_number INTEGER,
    qiraah_id INTEGER,
    text_variant TEXT,
    scholar_approved BOOLEAN DEFAULT 0
);

-- ملفات صوتية للتلاوة
CREATE TABLE audio_recitations (
    id INTEGER PRIMARY KEY,
    surah_id INTEGER,
    ayah_number INTEGER,
    reciter_name TEXT,
    riwayah TEXT,
    audio_file_path TEXT,
    license TEXT
);

-- فهرس بحث منزّه من التشكيل (لتحسين البحث الحالي)
CREATE TABLE ayat_search_index (
    ayah_id INTEGER,
    text_normalized TEXT  -- بدون تشكيل، لمطابقة أدق
);
```

**قبل بناء أي من هذه الجداول فعليًا:** يجب تأمين مصدر بيانات مرخّص لكل نوع
(نص القراءات، ملفات صوتية) بشكل منفصل — لا يمكن افتراض أن ترخيص Tanzil
النصي يغطي هذه الأنواع الأخرى من البيانات.
