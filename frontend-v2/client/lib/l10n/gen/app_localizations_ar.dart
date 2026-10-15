// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Autolinky';

  @override
  String get welcomeTitle => 'وظائف تناسبك، نجدها لك';

  @override
  String get welcomeSubtitle =>
      'ارفع سيرتك الذاتية مرة واحدة. يقرأها Autolinky ويتابع LinkedIn على مدار الساعة، ويجلب لك الوظائف المناسبة.';

  @override
  String get welcomePointMatch => 'وظائف تطابق سيرتك الذاتية، مع سبب كل تطابق';

  @override
  String get welcomePointFresh => 'وظائف جديدة كل بضع دقائق';

  @override
  String get welcomePointApply => 'قدّم بالبريد أو واتساب أو الرابط بلمسة واحدة';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get continueWithEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get orDivider => 'أو';

  @override
  String get legalPrefix => 'بالمتابعة، أنت توافق على';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get legalAnd => ' و';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get emailTitle => 'المتابعة بالبريد الإلكتروني';

  @override
  String get emailSubtitle => 'سنرسل إلى بريدك رابطًا لتسجيل الدخول. لا تحتاج إلى كلمة مرور.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get emailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get sendCode => 'إرسال رابط الدخول';

  @override
  String get verifyTitle => 'تحقق من بريدك';

  @override
  String verifySubtitle(String email) {
    return 'افتح رابط تسجيل الدخول الذي أرسلناه إلى $email. يمكنك العودة هنا لطلب رابط آخر.';
  }

  @override
  String get verifyButton => 'تحقق';

  @override
  String get resendCode => 'إعادة إرسال الرابط';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال خلال $secondsث';
  }

  @override
  String get codeSent => 'أرسلنا رابط دخول جديدًا';

  @override
  String get changeEmail => 'استخدام بريد آخر';

  @override
  String get navMatches => 'لك';

  @override
  String get navExplore => 'استكشاف';

  @override
  String get navProfile => 'حسابي';

  @override
  String get matchesTitle => 'وظائف مناسبة لك';

  @override
  String get matchesEmptyTitle => 'ستظهر هنا الوظائف المناسبة لك';

  @override
  String get matchesEmptyBody => 'ارفع سيرتك الذاتية وسنجد لك الوظائف التي تناسبك، مع سبب كل تطابق.';

  @override
  String get matchesMoreError => 'تعذّر تحميل المزيد من الوظائف.';

  @override
  String get tabApplied => 'قدّمت عليها';

  @override
  String get channelEmail => 'تقديم تلقائي';

  @override
  String get channelEasyApply => 'Easy Apply';

  @override
  String get channelWhatsapp => 'واتساب';

  @override
  String get channelLink => 'رابط تقديم';

  @override
  String get channelCompanySite => 'موقع الشركة';

  @override
  String get channelMessage => 'رسالة';

  @override
  String get channelComment => 'تعليق';

  @override
  String get channelEmailAbout => 'منشورات تطلب السيرة الذاتية بالبريد: يرسل Autolinky سيرتك نيابةً عنك.';

  @override
  String get channelEasyApplyAbout => 'وظائف على LinkedIn تقدّم عليها بلمسات قليلة داخل LinkedIn.';

  @override
  String get channelWhatsappAbout => 'منشورات بها رقم: راسل مسؤول التوظيف على واتساب.';

  @override
  String get channelLinkAbout => 'منشورات بها نموذج أو صفحة وظائف للتقديم.';

  @override
  String get channelCompanySiteAbout => 'وظائف على LinkedIn تقدّم عليها في موقع الشركة.';

  @override
  String get channelMessageAbout => 'منشورات تطلب أن تراسل صاحب المنشور.';

  @override
  String get channelCommentAbout => 'منشورات تطلب التعليق للتقديم.';

  @override
  String get bestFitFirst => 'الأنسب لك أولًا.';

  @override
  String get channelEmptyTitle => 'لا شيء هنا بعد';

  @override
  String get emptyPullHint => 'تصل وظائف جديدة كل بضع دقائق: اسحب للأسفل لتتحقق.';

  @override
  String get applyEmail => 'أرسل سيرتي';

  @override
  String get applyEasyApply => 'Easy Apply';

  @override
  String get applyWhatsapp => 'واتساب';

  @override
  String get applyLink => 'افتح الرابط';

  @override
  String get applyCompanySite => 'قدّم في موقعهم';

  @override
  String get applyMessage => 'أرسل رسالة';

  @override
  String get applyComment => 'علّق';

  @override
  String get applyChoose => 'قدّم';

  @override
  String get showDetails => 'عرض التفاصيل';

  @override
  String get thePost => 'المنشور';

  @override
  String get jobDescription => 'الوصف الوظيفي';

  @override
  String get noDescription => 'لا يوجد وصف لهذه الوظيفة.';

  @override
  String get waysToApply => 'طرق التقديم';

  @override
  String get openOnLinkedIn => 'افتح على LinkedIn';

  @override
  String appliedAgo(String when) {
    return 'تم التقديم · $when';
  }

  @override
  String get emailQueued => 'جارٍ الإرسال…';

  @override
  String emailSent(String when) {
    return 'أُرسلت السيرة · $when';
  }

  @override
  String get emailFailed => 'لم تُرسل';

  @override
  String appliedVia(String way) {
    return 'عبر $way';
  }

  @override
  String appliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلبًا',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
    );
    return '$_temp0';
  }

  @override
  String get appliedEmptyTitle => 'لم تقدّم على وظائف بعد';

  @override
  String get appliedEmptyBody => 'قدّم على وظيفة وستظهر هنا، لتعرف دائمًا أين قدّمت.';

  @override
  String get removeApplied => 'إزالة من قائمة التقديمات';

  @override
  String get removedApplied => 'أُزيلت من قائمة التقديمات';

  @override
  String get cannotRemoveSent => 'أُرسلت سيرتك بالبريد بالفعل: تبقى في قائمة التقديمات.';

  @override
  String get moreOptions => 'خيارات أخرى';

  @override
  String get didYouApplyTitle => 'هل قدّمت؟';

  @override
  String get didYouApplyBody => 'اختر نعم لنحفظها في قائمة التقديمات، فتعرف أين قدّمت.';

  @override
  String get yesApplied => 'نعم، قدّمت';

  @override
  String get notYet => 'ليس بعد';

  @override
  String get savedApplied => 'أُضيفت إلى قائمة التقديمات';

  @override
  String get applyUnavailable => 'طريقة التقديم هذه لم تعد موجودة في الوظيفة.';

  @override
  String get applyCannotOpen => 'تعذّر فتحها على هذا الهاتف.';

  @override
  String get chooseWayTitle => 'كيف تريد التقديم؟';

  @override
  String whatsappMessage(String title) {
    return 'Kindly find my attached CV for the position of $title.';
  }

  @override
  String get sendCvTitle => 'إرسال سيرتك؟';

  @override
  String get sendCvTo => 'إلى';

  @override
  String get sendCvSubject => 'الموضوع';

  @override
  String get sendCvAttachment => 'المرفق';

  @override
  String get sendCvButton => 'إرسال';

  @override
  String get autoApplyTitle => 'التقديم التلقائي';

  @override
  String get autoApplyBody => 'فعّله ويرسل Autolinky سيرتك إلى كل وظيفة جديدة هنا تناسبك، من Gmail الخاص بك.';

  @override
  String get autoApplyTurnOn => 'تفعيل';

  @override
  String get autoApplyOn => 'مفعّل';

  @override
  String get connectEmailTitle => 'اربط Gmail الخاص بك';

  @override
  String get connectEmailBody => 'يرسل Autolinky طلباتك من Gmail الخاص بك، ومعها سيرتك الذاتية.';

  @override
  String get connectEmailPointAddress => 'تُرسل من عنوانك، فتصلك الردود مباشرة';

  @override
  String get connectEmailPointLetter => 'خطاب تقديم قصير مكتوب لكل وظيفة';

  @override
  String get connectEmailPointStop => 'أوقفه مؤقتًا في أي وقت';

  @override
  String get gotIt => 'حسنًا';

  @override
  String get gmailTitle => 'ربط Gmail';

  @override
  String get gmailIntroSend =>
      'تُرسل سيرتك من Gmail الخاص بك، فتصلك الردود مباشرة. اربطه مرة واحدة: وسيستخدمه كل «أرسل سيرتي».';

  @override
  String get gmailIntroAuto =>
      'يرسل التقديم التلقائي سيرتك من Gmail الخاص بك. اربطه مرة واحدة، ثم اختر طريقة عمل التقديم التلقائي.';

  @override
  String get gmailIntroSettings =>
      'يرسل Autolinky طلباتك من Gmail الخاص بك بكلمة مرور تطبيق: كلمة مرور منفصلة يصنعها Google لتطبيق واحد، ويمكنك حذفها في أي وقت.';

  @override
  String get gmailInvalidBanner =>
      'توقف Gmail عن قبول كلمة مرور التطبيق (ربما حُذفت أو أُوقف التحقق بخطوتين). أنشئ واحدة جديدة والصقها بالأسفل.';

  @override
  String get gmailStepsTitle => 'احصل على كلمة مرور تطبيق (دقيقتان)';

  @override
  String get gmailStep1 => 'فعّل التحقق بخطوتين لحساب Google: كلمات مرور التطبيقات تحتاجه.';

  @override
  String get gmailStep1Button => 'فتح التحقق بخطوتين';

  @override
  String get gmailStep2 => 'افتح كلمات مرور التطبيقات، واكتب Autolinky اسمًا للتطبيق، ثم اضغط «إنشاء».';

  @override
  String get gmailStep2Button => 'فتح كلمات مرور التطبيقات';

  @override
  String get gmailStep3 =>
      'انسخ كلمة المرور المكوّنة من 16 حرفًا التي يعرضها Google والصقها بالأسفل. استخدم حساب Google الخاص بالعنوان بالأسفل.';

  @override
  String get gmailAddressLabel => 'عنوان Gmail';

  @override
  String get gmailNameLabel => 'اسمك';

  @override
  String get gmailNameHelper => 'يرى مسؤولو التوظيف هذا الاسم، ويُوقَّع به خطابك.';

  @override
  String get gmailPasswordLabel => 'كلمة مرور التطبيق';

  @override
  String get gmailPasswordHelper => '16 حرفًا. لا بأس بالمسافات.';

  @override
  String get gmailPasswordKeep => 'اتركها فارغة للإبقاء على المحفوظة.';

  @override
  String get gmailPaste => 'لصق';

  @override
  String get gmailShowPassword => 'إظهار كلمة المرور';

  @override
  String get gmailHidePassword => 'إخفاء كلمة المرور';

  @override
  String get gmailConnect => 'تحقق واربط';

  @override
  String get gmailSave => 'حفظ';

  @override
  String get gmailChecking => 'جارٍ التحقق مع Gmail…';

  @override
  String get gmailConnected => 'تم ربط Gmail';

  @override
  String get gmailSavedUnverified => 'تم الحفظ. تعذّر الوصول إلى Gmail للتحقق الآن: ستتحقق منه أول سيرة تُرسل.';

  @override
  String get gmailPrivacy =>
      'كلمة مرور التطبيق مشفّرة وتُستخدم فقط لإرسال طلباتك. احذفها من هنا أو من حساب Google في أي وقت.';

  @override
  String get gmailSignatureLabel => 'التوقيع';

  @override
  String get gmailSignatureHelper => 'تحت اسمك في كل رسالة. مأخوذ من سيرتك: عدّله كما تحب.';

  @override
  String get gmailSignatureReset => 'استخدم توقيع سيرتي';

  @override
  String get sendCvLetterAi => 'مكتوب لهذه الوظيفة من سيرتك. يمكنك تعديله قبل الإرسال.';

  @override
  String get sendCvLetterTemplate => 'خطاب قصير. يمكنك تعديله قبل الإرسال.';

  @override
  String get sendCvLetterEmpty => 'اكتب بضعة أسطر لمسؤول التوظيف';

  @override
  String get gmailStatusOk => 'مربوط';

  @override
  String get gmailStatusUnverified => 'محفوظ، لم يُتحقق منه بعد';

  @override
  String get gmailStatusInvalid => 'يحتاج كلمة مرور تطبيق جديدة';

  @override
  String get gmailDisconnect => 'فصل Gmail';

  @override
  String get gmailDisconnectTitle => 'فصل Gmail؟';

  @override
  String get gmailDisconnectBody =>
      'سينسى Autolinky كلمة مرور التطبيق وسيتوقف التقديم التلقائي. لإلغائها من Google أيضًا، احذفها من كلمات مرور التطبيقات.';

  @override
  String get gmailDisconnected => 'تم فصل Gmail';

  @override
  String get gmailErrorName => 'اكتب اسمك';

  @override
  String get gmailErrorFormat => 'كلمة مرور التطبيق 16 حرفًا، مثل abcd efgh ijkl mnop.';

  @override
  String get gmailErrorWrong => 'لم يقبل Gmail كلمة مرور التطبيق هذه. تأكد أنها أُنشئت لهذا العنوان، ثم حاول مجددًا.';

  @override
  String get gmailErrorNotApp =>
      'يبدو أنها كلمة مرور Google. يحتاج Autolinky كلمة مرور تطبيق (الخطوة 2)، وليس كلمة مرورك الحقيقية.';

  @override
  String get gmailErrorBlocked => 'يطلب Google أن تسجّل الدخول إلى Gmail من المتصفح أولًا. افعل ذلك، ثم حاول مجددًا.';

  @override
  String get gmailErrorUnavailable => 'الإرسال من Gmail غير متاح الآن. حاول لاحقًا.';

  @override
  String get gmailErrorNeedPassword => 'الصق كلمة مرور تطبيق لهذا العنوان.';

  @override
  String get sendCvFrom => 'من';

  @override
  String get sendCvLetter => 'الخطاب';

  @override
  String cvSentTo(String address) {
    return 'أُرسلت سيرتك إلى $address';
  }

  @override
  String get sendAgain => 'أرسل مجددًا';

  @override
  String get appliedAutomatically => 'أرسلها التقديم التلقائي';

  @override
  String get emailErrorAddressRefused => 'لم تُرسل: رفض عنوان الوظيفة الرسالة.';

  @override
  String get emailErrorMessageRefused => 'لم تُرسل: رفض Gmail الرسالة.';

  @override
  String get emailErrorInterrupted => 'انقطع الإرسال: راجع مجلد «المرسل» في Gmail.';

  @override
  String get emailErrorGmailLimit => 'وصلت إلى حد الإرسال اليومي في Gmail. حاول غدًا.';

  @override
  String get emailErrorGmailBusy => 'لم يستجب Gmail. حاول بعد دقيقة.';

  @override
  String get emailErrorDailyLimit => 'هذا حد اليوم من السير الذاتية، حفاظًا على Gmail الخاص بك. حاول غدًا.';

  @override
  String get emailErrorNoCv => 'ارفع سيرتك الذاتية أولًا: هي ما يُرفق.';

  @override
  String get autoApplyOffTitle => 'التقديم التلقائي متوقف';

  @override
  String get autoApplyOffBody =>
      'فعّله ويرسل Autolinky سيرتك إلى الوظائف التي تناسبك، من Gmail الخاص بك، على دفعات صغيرة.';

  @override
  String get autoApplyOnTitle => 'التقديم التلقائي مفعّل';

  @override
  String autoApplySentToday(int sent, int limit) {
    return 'أُرسلت $sent من $limit سيرة اليوم';
  }

  @override
  String autoApplyNextIn(int minutes) {
    return 'السيرة التالية بعد $minutes دقيقة تقريبًا';
  }

  @override
  String get autoApplyNextSoon => 'السيرة التالية خلال لحظات';

  @override
  String autoApplyWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وظيفة في الانتظار',
      few: '$count وظائف في الانتظار',
      two: 'وظيفتان في الانتظار',
      one: 'وظيفة واحدة في الانتظار',
      zero: 'لا وظائف في الانتظار: يرسل عند وصول وظائف جديدة تناسبك',
    );
    return '$_temp0';
  }

  @override
  String get autoApplyStart => 'ابدأ التقديم التلقائي';

  @override
  String get autoApplyStop => 'إيقاف التقديم التلقائي';

  @override
  String get autoApplyBackground => 'تابع في الخلفية';

  @override
  String get autoApplyBackgroundNote =>
      'يمكنك إغلاق Autolinky: الإرسال يتم على خادمنا، وسيصلك إشعار عند إرسال كل سيرة.';

  @override
  String get autoApplyMinMatch => 'فقط الوظائف التي تناسبك بنسبة لا تقل عن';

  @override
  String get autoApplyDailyLimit => 'أقصى عدد من السير يوميًا';

  @override
  String get autoApplyGap => 'أقل عدد دقائق بين سيرتين';

  @override
  String get autoApplyGapSafety =>
      'يسمح Gmail للحساب الشخصي بإرسال حتى 500 رسالة يوميًا، لكن الإرسال بأسرع من نحو 20 رسالة في الساعة قد يوقف إرسالك حتى يوم كامل. أقل فاصل يستخدمه Autolinky هو 3 دقائق.';

  @override
  String get autoApplyHowTitle => 'كيف يرسل';

  @override
  String get autoApplyHowGap =>
      'واحدة في كل مرة، بفاصل لا يقل عن الدقائق التي اخترتها مع زيادة عشوائية بسيطة، كأنه شخص';

  @override
  String get autoApplyHowHours => 'ليلًا ونهارًا، وبحد أقصى 15 في الساعة';

  @override
  String get autoApplyHowOnce => 'لا يرسل لنفس مسؤول التوظيف مرتين في الشهر، ولا لوظيفة قدّمت عليها';

  @override
  String get autoApplyHowFresh => 'فقط وظائف آخر أسبوعين، الأنسب أولًا';

  @override
  String get autoApplyHowGmail => 'من Gmail الخاص بك: كل رسالة في مجلد «المرسل»';

  @override
  String get autoApplySendsFrom => 'يرسل من';

  @override
  String get autoApplyNotificationsOff => 'الإشعارات متوقفة: ستجد ما أُرسل في «قدّمت عليها».';

  @override
  String get autoApplyProblemEmail => 'توقف Gmail عن قبول كلمة مرور التطبيق. لن يُرسل شيء حتى تضيف واحدة جديدة.';

  @override
  String get autoApplyProblemNoCv => 'ارفع سيرتك: لا يوجد ما يرفقه التقديم التلقائي.';

  @override
  String get autoApplyProblemLimit => 'تم الوصول إلى حد Gmail اليومي: يكمل التقديم التلقائي غدًا.';

  @override
  String get autoApplyProblemBusy => 'طلب Gmail الانتظار قليلًا: يكمل التقديم التلقائي قريبًا.';

  @override
  String get autoApplyProblemOffline => 'الإرسال متوقف لحظات: تُرسل السير الذاتية فور عودته.';

  @override
  String get autoApplyFixGmail => 'إصلاح Gmail';

  @override
  String get autoApplyUploadCv => 'رفع السيرة';

  @override
  String get autoApplyManage => 'إدارة';

  @override
  String autoApplyBannerOn(int sent) {
    return 'مفعّل · أُرسلت $sent اليوم';
  }

  @override
  String get autoApplyBannerProblem => 'يحتاج انتباهك';

  @override
  String autoApplySentSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أرسل التقديم التلقائي سيرتك إلى $count وظيفة',
      few: 'أرسل التقديم التلقائي سيرتك إلى $count وظائف',
      two: 'أرسل التقديم التلقائي سيرتك إلى وظيفتين',
      one: 'أرسل التقديم التلقائي سيرتك إلى وظيفة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get applyingSection => 'التقديم';

  @override
  String get settingsGmail => 'Gmail';

  @override
  String get settingsGmailNone => 'غير مربوط';

  @override
  String get autoApplyOff => 'متوقف';

  @override
  String get notifyChannel => 'عندما يرسل التقديم التلقائي سيرتك';

  @override
  String notifySentOne(String company) {
    return 'أُرسلت سيرتك إلى $company';
  }

  @override
  String notifySentMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أرسل التقديم التلقائي $count سيرة',
      few: 'أرسل التقديم التلقائي $count سير',
      two: 'أرسل التقديم التلقائي سيرتين',
    );
    return '$_temp0';
  }

  @override
  String get notifySeeApplied => 'تجدها في «قدّمت عليها»';

  @override
  String get notifyProblemTitle => 'توقف التقديم التلقائي';

  @override
  String newJobsBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وظيفة جديدة',
      few: '$count وظائف جديدة',
      two: 'وظيفتان جديدتان',
      one: 'وظيفة جديدة',
    );
    return '$_temp0';
  }

  @override
  String notifyNewMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وظيفة جديدة تناسبك',
      few: '$count وظائف جديدة تناسبك',
      two: 'وظيفتان جديدتان تناسبانك',
      one: 'وظيفة جديدة تناسبك',
    );
    return '$_temp0';
  }

  @override
  String get notifyNewMatchesBody => 'افتح Autolinky لتراها وتقدّم عليها.';

  @override
  String get exploreSearchHint => 'ابحث عن وظيفة أو شركة أو مهارة';

  @override
  String get clearSearch => 'مسح';

  @override
  String get filterAll => 'الكل';

  @override
  String get exploreHeader => 'الأحدث أولًا، من آخر 30 يومًا';

  @override
  String get exploreNoResultsTitle => 'لم نجد وظائف';

  @override
  String get exploreNoResultsBody => 'جرّب كلمات أخرى أو طريقة تقديم أخرى.';

  @override
  String get listEnd => 'هذا كل شيء الآن. تصل وظائف جديدة باستمرار.';

  @override
  String matchPercent(int percent) {
    return 'تطابق $percent%';
  }

  @override
  String get yourSkills => 'مهاراتك';

  @override
  String get missingSkills => 'ينقصك';

  @override
  String get fitSameRole => 'نفس وظيفتك';

  @override
  String get fitSimilarRole => 'قريبة من وظيفتك';

  @override
  String get fitSameField => 'في مجالك';

  @override
  String get fitRelatedField => 'مجال قريب من مجالك';

  @override
  String get fitSkillsOnly => 'تناسب مهاراتك';

  @override
  String get levelFitMatch => 'تناسب مستواك';

  @override
  String get levelFitClose => 'قريبة من مستواك';

  @override
  String get workOnsite => 'من المقر';

  @override
  String get workRemote => 'عن بُعد';

  @override
  String get workHybrid => 'هجين';

  @override
  String get placeNotGiven => 'المكان غير مذكور';

  @override
  String get jobFullTime => 'دوام كامل';

  @override
  String get jobPartTime => 'دوام جزئي';

  @override
  String get jobContract => 'عقد';

  @override
  String get jobTemporary => 'مؤقت';

  @override
  String get jobInternship => 'تدريب';

  @override
  String get jobFreelance => 'عمل حر';

  @override
  String get jobVolunteer => 'تطوع';

  @override
  String get postedJustNow => 'الآن';

  @override
  String postedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String postedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String postedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String postedWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوع',
      many: 'منذ $count أسبوعًا',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع',
    );
    return '$_temp0';
  }

  @override
  String postedMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهر',
      many: 'منذ $count شهرًا',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر',
    );
    return '$_temp0';
  }

  @override
  String get uploadCv => 'ارفع سيرتك الذاتية';

  @override
  String get exploreTitle => 'استكشاف';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get accountSection => 'الحساب';

  @override
  String get signedInWithGoogle => 'مسجّل الدخول باستخدام Google';

  @override
  String get signedInWithEmail => 'مسجّل الدخول بالبريد الإلكتروني';

  @override
  String get cvSection => 'سيرتك الذاتية';

  @override
  String get cvMissingTitle => 'لا توجد سيرة ذاتية بعد';

  @override
  String get cvMissingBody => 'أضف سيرتك الذاتية لنطابقك مع الوظائف.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmBody => 'يمكنك تسجيل الدخول مرة أخرى في أي وقت.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'حسب الجهاز';

  @override
  String get about => 'عن التطبيق';

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String versionWithUpdate(String version, int patch) {
    return 'الإصدار $version · التحديث $patch';
  }

  @override
  String get updatedTitle => 'تم تحديث التطبيق';

  @override
  String updatedBody(int patch) {
    return 'وصل تحديث جديد وهو يعمل الآن (التحديث $patch). لا تحتاج لفعل أي شيء.';
  }

  @override
  String get updatedOk => 'تمام';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get errorTitle => 'حدث خطأ';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorSessionExpired => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get errorForbidden => 'لا يمكن لهذا الحساب استخدام Autolinky حاليًا. تواصل مع الدعم.';

  @override
  String get errorRateLimited => 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String errorRateLimitedFor(int seconds) {
    return 'محاولات كثيرة. حاول مرة أخرى بعد $seconds ثانية.';
  }

  @override
  String get errorUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorInvalidCode => 'رابط الدخول غير صالح أو انتهت صلاحيته. اطلب رابطًا جديدًا.';

  @override
  String get errorNotConfigured => 'طريقة تسجيل الدخول هذه غير متاحة بعد. استخدم طريقة أخرى.';

  @override
  String get configMissingTitle => 'هذه النسخة غير مُعدّة';

  @override
  String configMissingBody(String names) {
    return 'إعدادات ناقصة: $names. ابنِ التطبيق باستخدام --dart-define-from-file=env/dev.json';
  }

  @override
  String get continueButton => 'متابعة';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get skip => 'تخطٍّ';

  @override
  String get scopeTitle => 'أين تريد أن تعمل؟';

  @override
  String get scopeSubtitle => 'سنعرض لك الوظائف هناك ونواصل البحث عن المزيد. يمكنك تغييره في أي وقت.';

  @override
  String get scopeEgypt => 'مصر فقط';

  @override
  String get scopeEgyptBody => 'وظائف داخل مصر';

  @override
  String get scopeEgyptGulf => 'مصر والخليج';

  @override
  String get scopeEgyptGulfBody => 'مصر والسعودية والإمارات وقطر والكويت والبحرين وعُمان';

  @override
  String get scopeEgyptRemote => 'مصر + عن بُعد';

  @override
  String get scopeEgyptRemoteBody => 'وظائف داخل مصر، ووظائف عن بُعد من أي دولة';

  @override
  String get scopeEgyptGulfRemote => 'مصر والخليج + عن بُعد';

  @override
  String get scopeEgyptGulfRemoteBody => 'مصر ودول الخليج، ووظائف عن بُعد من أي دولة';

  @override
  String get scopeRemote => 'عن بُعد';

  @override
  String get scopeRemoteBody => 'وظائف عن بُعد من أي دولة';

  @override
  String get scopeWorldwide => 'أي مكان في العالم';

  @override
  String get scopeWorldwideBody => 'كل الوظائف في كل الدول';

  @override
  String get cvTitle => 'ارفع سيرتك الذاتية';

  @override
  String get cvSubtitle => 'نقرؤها مرة واحدة لملء ملفك. لا يراها أحد غيرك.';

  @override
  String get cvPick => 'اختر ملفًا';

  @override
  String get cvPickHint => 'PDF أو Word (.docx)، حتى 4 ميجابايت';

  @override
  String cvUploading(int percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get cvReading => 'نقرأ سيرتك الذاتية';

  @override
  String get cvReadingSkills => 'نستخرج مهاراتك';

  @override
  String get cvReadingTitles => 'نختار الوظائف التي سنبحث عنها';

  @override
  String get cvReadingHint => 'يستغرق ذلك بضع ثوانٍ.';

  @override
  String get cvUseCurrent => 'المتابعة بهذه السيرة';

  @override
  String get cvUploadNew => 'رفع سيرة جديدة';

  @override
  String get cvReplace => 'استبدال';

  @override
  String get cvDelete => 'حذف السيرة الذاتية';

  @override
  String get cvDeleteConfirmTitle => 'حذف سيرتك الذاتية؟';

  @override
  String get cvDeleteConfirmBody => 'سيُحذف الملف ونصه نهائيًا. يبقى ملفك الشخصي كما هو.';

  @override
  String get cvDeleted => 'تم حذف السيرة الذاتية';

  @override
  String get delete => 'حذف';

  @override
  String cvPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحة',
      many: '$count صفحة',
      few: '$count صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
      zero: 'بلا صفحات',
    );
    return '$_temp0';
  }

  @override
  String cvUploadedOn(String date) {
    return 'رُفعت في $date';
  }

  @override
  String get cvPartial => 'لم نتمكن من قراءة سيرتك بالكامل. راجع ملفك أو دعنا نقرؤها مرة أخرى.';

  @override
  String get cvReanalyze => 'اقرأها مرة أخرى';

  @override
  String get cvErrTooLarge => 'الملف أكبر من 4 ميجابايت.';

  @override
  String get cvErrBadType => 'نقبل ملفات PDF أو Word (.docx) فقط.';

  @override
  String get cvErrEmpty => 'الملف فارغ.';

  @override
  String get cvErrUnreadable => 'تعذّر فتح الملف. جرّب حفظه مرة أخرى بصيغة PDF.';

  @override
  String get cvErrEncrypted => 'ملف PDF محمي بكلمة مرور. ارفع نسخة بدونها.';

  @override
  String get cvErrNoText => 'ملف PDF عبارة عن صورة ممسوحة بلا نص. ارفع ملف PDF محفوظًا من Word أو Google Docs.';

  @override
  String get cvErrNotCv => 'لا يبدو هذا الملف سيرة ذاتية.';

  @override
  String get cvErrAiBusy => 'لا يمكننا قراءة السير الذاتية الآن. حاول مرة أخرى بعد دقائق.';

  @override
  String get cvErrTooMany => 'رفعت سيرًا ذاتية كثيرة اليوم. حاول مرة أخرى لاحقًا.';

  @override
  String get reviewTitle => 'هذا ما وجدناه';

  @override
  String get reviewSubtitle => 'راجعه وعدّل ما تريد. الوظائف المقترحة مبنية عليه.';

  @override
  String get fieldHeadline => 'المسمى المهني';

  @override
  String get fieldHeadlineHint => 'مثال: مهندس شبكات، 3 سنوات في شركات الإنترنت';

  @override
  String get fieldRoles => 'الوظائف التي تريدها';

  @override
  String get fieldRolesHelp =>
      'الوظائف المقترحة وبحثنا في LinkedIn مبنيان عليها. حتى 5. غير موجودة في القائمة؟ اكتبها وأضفها.';

  @override
  String get fieldLevel => 'المستوى';

  @override
  String get levelIntern => 'متدرب';

  @override
  String get levelJunior => 'مبتدئ';

  @override
  String get levelMid => 'متوسط الخبرة';

  @override
  String get levelSenior => 'خبير';

  @override
  String get levelManager => 'مدير';

  @override
  String get fieldYears => 'سنوات الخبرة';

  @override
  String get fieldSkills => 'المهارات';

  @override
  String get fieldExtraSkills => 'أيضًا في سيرتك';

  @override
  String get fieldExtraSkillsHelp => 'تظهر في ملفك، ولا تُستخدم في المطابقة بعد.';

  @override
  String get fieldScope => 'أين تريد أن تعمل';

  @override
  String get add => 'إضافة';

  @override
  String get change => 'تغيير';

  @override
  String get searchHint => 'بحث';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get rolesRequired => 'أضف وظيفة واحدة على الأقل تريدها.';

  @override
  String get limitReached => 'وصلت إلى الحد الأقصى.';

  @override
  String get finishSetup => 'اعرض وظائفي';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get errUnknownValues => 'بعض الاختيارات لم تعد متاحة. احذفها واحفظ مرة أخرى.';

  @override
  String get editProfile => 'تعديل الملف';

  @override
  String get jobPreferences => 'تفضيلات العمل';

  @override
  String get notSet => 'غير محدد';

  @override
  String get setUpProfile => 'أكمل ملفك';

  @override
  String get setUpProfileBody => 'أخبرنا أين تريد أن تعمل وارفع سيرتك الذاتية. يستغرق ذلك دقيقة.';

  @override
  String pickerAddTitle(String text) {
    return 'إضافة «$text»';
  }

  @override
  String pickerAddSkill(String text) {
    return 'إضافة «$text»';
  }

  @override
  String get addedToExtraSkills => 'أُضيفت إلى مهاراتك';

  @override
  String jobsLimit(int count) {
    return 'يمكنك اختيار $count وظائف بحد أقصى. احذف واحدة لتضيف غيرها.';
  }

  @override
  String get firstJobsTitle => 'نبحث لك عن أولى وظائفك';

  @override
  String get firstJobsSubtitle =>
      'نبحث الآن على LinkedIn عن المسميات الوظيفية التي اخترتها. تظهر الوظائف هنا فور العثور عليها.';

  @override
  String get firstJobsDoneTitle => 'وظائفك جاهزة';

  @override
  String get firstJobsDoneSubtitle => 'بحثنا عن كل مسمياتك الوظيفية، وتصل وظائف جديدة باستمرار ليلًا ونهارًا.';

  @override
  String get firstJobsSlowTitle => 'ما زلنا نبحث';

  @override
  String get firstJobsSlowSubtitle => 'يستغرق البحث وقتًا أطول من المعتاد. ستظهر وظائفك في «لك» فور العثور عليها.';

  @override
  String firstJobsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وجدنا $count وظيفة حتى الآن',
      few: 'وجدنا $count وظائف حتى الآن',
      two: 'وجدنا وظيفتين حتى الآن',
      one: 'وجدنا وظيفة واحدة حتى الآن',
      zero: 'لا وظائف بعد',
    );
    return '$_temp0';
  }

  @override
  String firstJobsFoundDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وجدنا $count وظيفة',
      few: 'وجدنا $count وظائف',
      two: 'وجدنا وظيفتين',
      one: 'وجدنا وظيفة واحدة',
      zero: 'لم نجد وظائف بعد',
    );
    return '$_temp0';
  }

  @override
  String firstJobsFoundMore(int count) {
    return 'وجدنا أكثر من $count وظيفة';
  }

  @override
  String get firstJobsNoneYet => 'لا توجد وظيفة مناسبة بعد. سنواصل البحث، وستظهر الوظائف الجديدة في «لك».';

  @override
  String get firstJobsTipPosts => 'نقرأ أحدث منشورات التوظيف على LinkedIn…';

  @override
  String get firstJobsTipJobs => 'نبحث في LinkedIn Jobs أيضًا…';

  @override
  String get firstJobsTipMatch => 'نطابق كل وظيفة مع مهاراتك ومستواك…';

  @override
  String get firstJobsTipApply => 'نجد طريقة التقديم: البريد أو واتساب أو Easy Apply…';

  @override
  String get firstJobsSeeNow => 'اعرض وظائفي الآن';

  @override
  String get firstJobsSeeAll => 'اعرض كل وظائفي';

  @override
  String errorCode(String code) {
    return 'رمز الخطأ: $code';
  }

  @override
  String get upgradeTitle => 'افتح التقديم بلا حدود';

  @override
  String upgradeUsedUp(int limit) {
    return 'استخدمت طلباتك المجانية الـ $limit. اشترك لترسل سيرتك إلى كل وظيفة تناسبك، بنفسك أو بالتقديم التلقائي.';
  }

  @override
  String get upgradeIntro => 'أرسل سيرتك إلى كل وظيفة تناسبك، بنفسك أو بالتقديم التلقائي، بلا حدود.';

  @override
  String get upgradePerkUnlimited => 'طلبات بالبريد بلا حدود';

  @override
  String get upgradePerkAuto => 'تقديم تلقائي ليلًا ونهارًا، لكل الوظائف التي تناسبك';

  @override
  String get upgradePerkLetters => 'خطاب تقديم مكتوب لكل وظيفة';

  @override
  String get upgradeButton => 'اشترك';

  @override
  String upgradeHow(String email) {
    return 'ستتحدث معنا على واتساب للاشتراك. يُفعَّل اشتراكك لـ $email فور الدفع.';
  }

  @override
  String get upgradeHowNoEmail =>
      'ستتحدث معنا على واتساب للاشتراك. يُفعَّل اشتراكك لحساب Gmail الذي سجّلت به فور الدفع.';

  @override
  String lockedJobsBody(int limit) {
    return 'استخدمت طلباتك المجانية الـ $limit. تصل وظائف جديدة تناسبك باستمرار: اشترك لتقدّم عليها كلها.';
  }

  @override
  String get autoApplyProblemFreeLimit => 'انتهت طلباتك المجانية. اشترك لتواصل التقديم.';

  @override
  String get freeUsedTitle => 'انتهت الطلبات المجانية';

  @override
  String freeLeft(int left, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'بقي $left طلبًا مجانيًا من $limit',
      few: 'بقي $left طلبات مجانية من $limit',
      two: 'بقي طلبان مجانيان من $limit',
      one: 'بقي طلب مجاني واحد من $limit',
      zero: 'لم تبقَ طلبات مجانية',
    );
    return '$_temp0';
  }

  @override
  String get planTitle => 'الاشتراك';

  @override
  String get planFree => 'مجاني';

  @override
  String get planPro => 'Pro · طلبات بلا حدود';

  @override
  String planProUntil(String date) {
    return 'Pro · حتى $date';
  }

  @override
  String get proWelcomeTitle => 'أهلاً بك في Pro!';

  @override
  String get proWelcomeBody => 'تم تفعيل اشتراكك، شكراً لانضمامك! كل الوظائف المناسبة لك متاحة لك الآن.';

  @override
  String get proWelcomeButton => 'هيا بنا';

  @override
  String get gmailAccountOnly => 'حساب Gmail الذي سجّلت به. منه تُرسل طلباتك وعليه اشتراكك.';

  @override
  String gmailErrorNotAccount(String email) {
    return 'استخدم حساب Gmail الذي سجّلت به: $email';
  }

  @override
  String get autoApplyHomeOff => 'متوقف · يرسل سيرتك إلى الوظائف الجديدة التي تناسبك';

  @override
  String get autoApplyHomeSetup => 'متوقف · إعداد Gmail لمرة واحدة، نحو دقيقتين';

  @override
  String get autoApplyHomeUpgrade => 'اشترك لتفعيله';

  @override
  String get autoApplyTurningOn => 'جارٍ التفعيل…';

  @override
  String get autoApplyTurningOff => 'جارٍ الإيقاف…';

  @override
  String get autoApplyHomeError => 'تعذّر تحميل التقديم التلقائي. اضغط لإعادة المحاولة.';

  @override
  String get undo => 'تراجع';

  @override
  String get done => 'تم';

  @override
  String get autoApplyReadyTitle => 'كل شيء جاهز!';

  @override
  String get autoApplyReadyBody =>
      'التقديم التلقائي مفعّل. يرسل Autolinky سيرتك الآن إلى الوظائف الجديدة التي تناسبك، من Gmail الخاص بك:';

  @override
  String autoApplyReadyMatch(int percent) {
    return 'الوظائف التي تناسبك بنسبة $percent% أو أكثر';
  }

  @override
  String autoApplyReadyPace(int count, int minutes) {
    return 'حتى $count سيرة يوميًا، بفاصل $minutes دقيقة على الأقل';
  }

  @override
  String get autoApplyAdjust => 'تعديل الإعدادات';

  @override
  String get autoApplyConnectGmail => 'اربط Gmail الخاص بك';

  @override
  String get autoApplyConnectGmailBody => 'منه يرسل التقديم التلقائي. 3 خطوات سريعة.';

  @override
  String get setupDuration => '3 خطوات سريعة · نحو دقيقتين';

  @override
  String get setupTwoStepTitle => 'فعّل التحقق بخطوتين';

  @override
  String get setupTwoStepBody =>
      'تُرسل سيرتك من Gmail الخاص بك، فتصلك الردود مباشرة. ولذلك يحتاج Google إلى تفعيل التحقق بخطوتين في حسابك.';

  @override
  String get setupTwoStepHow1 => 'اضغط الزر بالأسفل: سيفتح حساب Google الخاص بك';

  @override
  String get setupTwoStepHow2 => 'فعّل التحقق بخطوتين واتبع خطوات Google';

  @override
  String get setupTwoStepHow3 => 'ارجع إلى Autolinky بعد تفعيله';

  @override
  String get setupAlreadyOn => 'مفعّل بالفعل';

  @override
  String get setupWelcomeBack => 'أهلًا بعودتك! إذا فُعّل التحقق بخطوتين، انتقل إلى الخطوة التالية.';

  @override
  String get setupNext => 'التالي';

  @override
  String get setupOpenAgain => 'افتحها مرة أخرى';

  @override
  String get setupAppPasswordTitle => 'أنشئ كلمة مرور تطبيق';

  @override
  String get setupAppPasswordBody =>
      'مفتاح من 16 حرفًا يصنعه Google لتطبيق واحد. يستخدمه Autolinky لإرسال طلباتك فقط، ولا يرى كلمة مرورك الحقيقية أبدًا.';

  @override
  String get setupAppPasswordHow1 => 'اكتب Autolinky اسمًا للتطبيق، ثم اضغط «إنشاء»';

  @override
  String get setupAppPasswordHow2 => 'انسخ كلمة المرور المكوّنة من 16 حرفًا التي يعرضها Google';

  @override
  String get setupAppPasswordHow3 => 'ارجع هنا: سيلصقها Autolinky لك';

  @override
  String get setupAppPasswordTip => 'لا تظهر صفحة كلمات مرور التطبيقات؟ فعّل التحقق بخطوتين أولًا (الخطوة 1).';

  @override
  String get setupHaveOne => 'لديّ واحدة بالفعل';

  @override
  String get setupCopied => 'نسختها';

  @override
  String get setupPreviewAppName => 'اسم التطبيق';

  @override
  String get setupPreviewCreate => 'إنشاء';

  @override
  String get setupPasteTitle => 'الصق كلمة مرور التطبيق';

  @override
  String get setupPasteBody => 'يتحقق منها Gmail قبل حفظها، ولا يُرسل أي شيء.';

  @override
  String get setupPastedForYou => 'لصقنا كلمة مرور التطبيق التي نسختها.';

  @override
  String setupLetters(int count) {
    return '$count من 16 حرفًا';
  }

  @override
  String get setupMakeNew => 'أنشئ واحدة جديدة';

  @override
  String get setupConnectTurnOn => 'اربط وفعّل';

  @override
  String get setupReconnect => 'توقف Gmail عن قبول كلمة مرور التطبيق. أنشئ واحدة جديدة، يستغرق ذلك دقيقتين.';

  @override
  String get filterNotApplied => 'لم أتقدّم لها';

  @override
  String get exploreAllAppliedTitle => 'تقدّمت لكل هذه الوظائف';

  @override
  String get exploreAllAppliedBody => 'ألغِ «لم أتقدّم لها» لتظهر مرة أخرى.';

  @override
  String get showAll => 'اعرض الكل';

  @override
  String get upgradePromoTitle => 'هل لديك كود خصم؟';

  @override
  String get upgradePromoBody => 'إن كان لديك كود، يُرسل مع طلبك على واتساب وتحصل على الخصم.';

  @override
  String get upgradePromoYes => 'نعم، لديّ كود';

  @override
  String get upgradePromoNo => 'لا، تابع إلى واتساب';

  @override
  String get upgradePromoEnter => 'اكتب كود الخصم';

  @override
  String get upgradePromoLabel => 'كود الخصم';

  @override
  String get upgradePromoHelper => 'اكتبه كما وصلك تمامًا.';

  @override
  String get upgradePromoContinue => 'تابع إلى واتساب';

  @override
  String get upgradePromoSkip => 'تابع بدون كود';

  @override
  String get emailLinkConfirmTitle => 'إكمال تسجيل الدخول';

  @override
  String get emailLinkConfirmBody =>
      'أكد البريد الإلكتروني الذي استلم هذا الرابط. إذا كنت تستخدم جهازًا آخر، أدخل نفس البريد الذي طلبت الرابط به.';

  @override
  String get emailLinkConfirm => 'تسجيل الدخول';

  @override
  String get continueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get signedInWithApple => 'مسجّل الدخول باستخدام Apple';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountBody =>
      'سيُحذف ملفك الشخصي وسيرتك الذاتية وطلبات التقديم واتصال البريد والأجهزة المسجّلة نهائيًا. يبقى سجل الاشتراك محفوظًا؛ تواصل مع الدعم بشأن الفوترة.';

  @override
  String deleteAccountConfirm(String email) {
    return 'اكتب $email لتأكيد الحذف.';
  }

  @override
  String get deleteAccountSending =>
      'لا تزال هناك رسالة بريد قيد المعالجة. يتوقف حذف الحساب حتى يتم تحديد حالة تسليمها.';
}
