import 'package:flutter/material.dart';

class GharadField {
  final String label;
  final bool multiline;
  final bool optional;

  const GharadField({
    required this.label,
    this.multiline = false,
    this.optional = false,
  });
}

class GharadOption {
  final String title;
  final String description;
  final List<GharadField> fields;
  final String iconPath;
  final String bannerPath;

  const GharadOption({
    required this.title,
    required this.description,
    required this.fields,
    this.iconPath = '',
    this.bannerPath = '',
  });
}

const List<GharadOption> mofawadGharadOptions = [
  GharadOption(
    title: 'مسطرة التبليغ',
    description:
        'تهدف مسطرة التبليغ إلى إيصال الاستدعاءات والوثائق القضائية إلى ذوي الشأن بصفة قانونية. تضمن هذه العملية إعلام الأطراف بمواعيد الجلسات والأحكام الصادرة في حقهم لضمان حقوق الدفاع. يقوم المفوض القضائي بتحرير محضر رسمي يثبت عملية التسليم أو التعذر وفق الضوابط المسطرية.',
    fields: [
      GharadField(label: 'نوع التبليغ'),
      GharadField(label: 'نوع الملف'),
      GharadField(label: 'المحكمة'),
      GharadField(label: 'اسم طالب التبليغ'),
      GharadField(label: 'اسم المبلغ إليه'),
      GharadField(label: 'مآل التبليغ', multiline: true),
      GharadField(label: 'ملاحظات', multiline: true, optional: true),
    ],
    bannerPath: 'assets/notification.png',
  ),
  GharadOption(
    title: 'مسطرة التنفيذ',
    description:
        'تعتبر مسطرة التنفيذ الجبري المرحلة الحاسمة لتحويل الأحكام القضائية من نصوص مكتوبة إلى واقع ملموس. تشمل هذه العملية إجراءات الحجز، البيع بالمزاد العلني، أو الإفراغ، وذلك لاستخلاص الحقوق لفائدة المحكوم لهم.',
    fields: [
      GharadField(label: 'نوع الإجراء'),
      GharadField(label: 'إسم الطالب'),
      GharadField(label: 'إسم المطلوب في الإجراء'),
      GharadField(label: 'ملخص للإجراء', multiline: true),
      GharadField(label: 'ملاحظات', multiline: true, optional: true),
    ],
    bannerPath: 'assets/execution.png',
  ),
];

const Map<String, List<String>> northCityData = {
  'طنجة': [
    'وسط المدينة',
    'طنجة المدينة',
    'بني مكادة',
    'مغوغة',
    'مالاباطا',
    'مسنانة',
    'طنجة مارينا',
    'البرانص',
    'مرس الخير',
  ],
  'تطوان': [
    'وسط المدينة',
    'تطوان المدينة',
    'سانية الرمل',
    'حي الولاية',
    'الملايين',
    'بوجراح',
    'الملاح',
    'كويلمة',
    'الخلوة',
  ],
  'العرائش': [
    'وسط المدينة',
    'العرائش المدينة',
    'حي الميناء',
    'المنار',
    'مولاي عبد السلام',
  ],
  'القصر الكبير': ['وسط المدينة', 'حي السلام'],
  'أصيلة': ['المدينة القديمة', 'أصيلة المدينة', 'المنطقة السياحية'],
  'المضيق': ['وسط المدينة', 'الميناء', 'المضيق المدينة'],
  'الفنيدق': ['وسط المدينة', 'باب سبتة'],
  'مرتيل': ['وسط المدينة', 'منطقة الشاطئ'],
  'شفشاون': [
    'المدينة القديمة',
    'شفشاون المدينة',
    'رأس الماء',
    'باب برد',
    'تارجيست',
  ],
  'وزان': ['وسط المدينة', 'حي القشريين', 'وزان المدينة'],
  'الحسيمة': [
    'وسط المدينة',
    'حي صباديا',
    'تالا يوسف',
    'الحسيمة المدينة',
    'إمزورن',
    'بني بوعياش',
  ],
  'كزناية': ['المنطقة الصناعية', 'وسط المدينة'],
  'واد لاو': ['وسط المدينة', 'الشاطئ'],
  'القصر الصغير': ['وسط المدينة', 'الميناء'],
};
