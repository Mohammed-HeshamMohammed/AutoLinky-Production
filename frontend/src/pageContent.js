// Product details are grounded in the mobile and backend implementation in
// X:/Autolinky-with-serverbased. Keep both languages in sync when features change.
import { LEGAL_PAGES } from './legalContent.js';

export { SITE_URL } from './config';

export const NAV = [
  ['features', 'Features', 'المميزات'],
  ['auto-apply', 'Auto Apply', 'التقديم التلقائي'],
  ['how-it-works', 'How it works', 'طريقة العمل'],
  ['pricing', 'Pricing', 'الأسعار'],
  ['faq', 'FAQ', 'الأسئلة الشائعة'],
];

export const PAGES = {
  features: {
    en: {
      title: 'AI job matching and application features | AutoLinky',
      description: 'See how AutoLinky finds jobs, matches them to your CV, prepares cover letters, and organizes applications by email, WhatsApp, and links.',
      eyebrow: 'Features',
      heading: 'Find the right jobs. Know why they fit.',
      intro: 'AutoLinky brings job discovery, CV matching, and application tracking into one Android app. You can review each opportunity and choose the way to apply that the job actually offers.',
      sections: [
        {
          heading: 'Job matches based on your CV',
          paragraphs: ['Upload a PDF or Word CV and set your profile. AutoLinky uses your role, skills, and experience to score new jobs and explain the match. Each job card shows the post, the available application methods, and the details you need to decide whether to apply.', 'A match score helps you prioritize; it is not a promise of an interview or a hiring decision. You stay in control of which opportunities to pursue.'],
        },
        {
          heading: 'Apply in the way the job allows',
          paragraphs: ['For jobs with an email address, Send my CV prepares a cover letter for that role and sends your CV from your connected Gmail. You can review and edit the letter before a manual send.', 'Other jobs may provide WhatsApp, Easy Apply, an application link, a company site, or a message or comment route. AutoLinky opens the relevant destination; you complete those steps yourself.'],
        },
        {
          heading: 'Track what happened',
          paragraphs: ['The Applied tab keeps the jobs you have applied to together. Email applications show whether they were sent or failed, and the app can notify you when Auto Apply sends a CV. You can see what went out rather than guessing whether an application was submitted.'],
        },
      ],
      answerHeading: 'What does AutoLinky do?',
      answer: 'AutoLinky is an Android job assistant that finds opportunities, compares them with your CV, and helps you apply. Email applications can be sent from your Gmail; links and WhatsApp applications still need your action.',
      related: ['how-it-works', 'auto-apply', 'faq'],
    },
    ar: {
      title: 'مميزات مطابقة الوظائف والتقديم | AutoLinky',
      description: 'تعرّف على طريقة بحث AutoLinky عن الوظائف، ومطابقتها مع سيرتك الذاتية، وكتابة خطاب التقديم، وتنظيم التقديم بالبريد أو واتساب أو الروابط.',
      eyebrow: 'المميزات',
      heading: 'اعثر على الوظائف المناسبة واعرف سبب ملاءمتها لك.',
      intro: 'يجمع AutoLinky البحث عن الوظائف ومطابقتها مع سيرتك الذاتية ومتابعة طلبات التقديم في تطبيق أندرويد واحد. يمكنك مراجعة كل فرصة واختيار طريقة التقديم المتاحة لها.',
      sections: [
        { heading: 'مطابقة الوظائف مع سيرتك الذاتية', paragraphs: ['ارفع سيرة ذاتية PDF أو Word وأكمل ملفك الشخصي. يستخدم AutoLinky دورك ومهاراتك وخبرتك لتقييم الوظائف الجديدة وشرح سبب المطابقة. تعرض بطاقة الوظيفة الإعلان وطرق التقديم المتاحة والتفاصيل اللازمة لاتخاذ القرار.', 'تساعدك درجة المطابقة على ترتيب أولوياتك؛ لكنها لا تضمن مقابلة أو قبولًا. القرار بشأن الوظائف التي تريدها يبقى لك.'] },
        { heading: 'قدّم بالطريقة التي تتيحها الوظيفة', paragraphs: ['عندما يتوفر بريد إلكتروني للوظيفة، يجهز خيار «أرسل سيرتي» خطاب تقديم مخصصًا ويرسل سيرتك من حساب Gmail الذي ربطته. يمكنك مراجعة الخطاب وتعديله قبل الإرسال اليدوي.', 'قد تتوفر أيضًا طرق أخرى مثل واتساب أو Easy Apply أو رابط تقديم أو موقع الشركة أو مراسلة صاحب الإعلان. يفتح AutoLinky الوجهة المناسبة، ثم تكمل هذه الخطوات بنفسك.'] },
        { heading: 'تابع ما حدث', paragraphs: ['تجمع صفحة «تم التقديم» الوظائف التي تقدمت إليها. توضح طلبات البريد ما إذا أُرسلت أو فشلت، ويمكن للتطبيق تنبيهك عندما يرسل التقديم التلقائي سيرتك الذاتية.'] },
      ],
      answerHeading: 'ماذا يفعل AutoLinky؟',
      answer: 'AutoLinky مساعد وظائف لأندرويد يبحث عن الفرص ويقارنها بسيرتك ويساعدك على التقديم. يمكن إرسال طلبات البريد من Gmail الخاص بك؛ أما الروابط وواتساب فتحتاج إلى إكمال الخطوات بنفسك.',
      related: ['how-it-works', 'auto-apply', 'faq'],
    },
  },
  'auto-apply': {
    en: {
      title: 'How Auto Apply works with Gmail | AutoLinky',
      description: 'Learn how AutoLinky Auto Apply sends CVs from your Gmail to matching email jobs, what you can control, and when it pauses.',
      eyebrow: 'Auto Apply',
      heading: 'Auto Apply works while you’re away.',
      intro: 'Auto Apply keeps working while the app is closed. For job posts with an application email address, the server selects eligible matches and sends your CV one application at a time after you enable it and connect Gmail.',
      sections: [
        { heading: 'You choose the limits', paragraphs: ['Set a minimum match and a daily number of CVs. AutoLinky prioritizes stronger matches, uses recent jobs, and spaces out messages. It avoids jobs you already applied to and avoids emailing the same address again within 30 days.', 'The app shows the count sent today, the next planned send, and jobs waiting. You can stop Auto Apply whenever you want.'] },
        { heading: 'Sent from your Gmail', paragraphs: ['AutoLinky connects to your Gmail with a separate, revocable access key. It checks the connection and stores the key encrypted on the server. It does not ask for your normal Google password. Applications appear in your Sent folder, and recruiter replies come to you.', 'The cover letter is based on your CV and the job. If AI is unavailable, the server uses a shorter template letter so an eligible email application can still be prepared.'] },
        { heading: 'What Auto Apply does not send', paragraphs: ['Auto Apply sends only email applications with a usable address. WhatsApp, Easy Apply, application forms, company sites, messages, and comments stay as manual actions in the app.', 'If a Gmail limit or connection problem stops sending, the app reports the issue. The free plan also stops email sends after its 20 included applications until a Pro subscription is active.'] },
      ],
      answerHeading: 'Can Auto Apply run when my phone is off?',
      answer: 'Yes. The sending service runs on the server after you enable Auto Apply, so the app does not have to remain open. Android notifications depend on the phone being able to check for activity.',
      related: ['features', 'pricing', 'faq'],
    },
    ar: {
      title: 'كيف يعمل التقديم التلقائي مع Gmail | AutoLinky',
      description: 'اعرف كيف يرسل التقديم التلقائي سيرتك من Gmail إلى وظائف البريد المناسبة، وما الحدود التي تتحكم بها ومتى يتوقف الإرسال.',
      eyebrow: 'التقديم التلقائي',
      heading: 'التقديم التلقائي يعمل حتى أثناء غيابك.',
      intro: 'يواصل التقديم التلقائي عمله بعد إغلاق التطبيق. في الوظائف التي تتضمن بريدًا إلكترونيًا للتقديم، يختار الخادم الوظائف المؤهلة ويرسل سيرتك طلبًا واحدًا في كل مرة بعد تفعيله وربط Gmail.',
      sections: [
        { heading: 'أنت تحدد الحدود', paragraphs: ['اختر أقل درجة مطابقة وعدد السير الذاتية يوميًا. يعطي AutoLinky الأولوية للوظائف الأقرب لك، ويستخدم الإعلانات الحديثة، ويترك وقتًا بين الرسائل. كما يتجنب الوظائف التي تقدمت إليها وإعادة الإرسال إلى البريد نفسه خلال 30 يومًا.', 'يعرض التطبيق عدد الرسائل المرسلة اليوم وموعد الإرسال التالي والوظائف المنتظرة. ويمكنك إيقاف التقديم التلقائي في أي وقت.'] },
        { heading: 'الإرسال من Gmail الخاص بك', paragraphs: ['يربط AutoLinky حساب Gmail بمفتاح وصول منفصل يمكن إلغاؤه. يتحقق من الاتصال ويخزن المفتاح مشفرًا على الخادم، ولا يطلب كلمة مرور حساب Google المعتادة. تظهر الطلبات في البريد المرسل وتصل ردود أصحاب العمل إليك.', 'يعتمد خطاب التقديم على سيرتك الذاتية والوظيفة. إذا لم تتوفر خدمة الذكاء الاصطناعي، يستخدم الخادم خطابًا مختصرًا جاهزًا.'] },
        { heading: 'ما الذي لا يرسله التقديم التلقائي؟', paragraphs: ['يرسل التقديم التلقائي طلبات البريد فقط عندما يتوفر عنوان صالح. تبقى طرق واتساب وEasy Apply والنماذج ومواقع الشركات والرسائل والتعليقات خطوات يدوية داخل التطبيق.', 'إذا أوقف الإرسال حد Gmail أو مشكلة في الاتصال، يوضح التطبيق السبب. وتتوقف رسائل الخطة المجانية بعد 20 طلبًا مشمولًا حتى تفعيل اشتراك Pro.'] },
      ],
      answerHeading: 'هل يعمل التقديم التلقائي والهاتف مغلق؟',
      answer: 'نعم. تعمل خدمة الإرسال على الخادم بعد تفعيل التقديم التلقائي، ولا يحتاج التطبيق إلى البقاء مفتوحًا. تعتمد إشعارات أندرويد على قدرة الهاتف على التحقق من النشاط.',
      related: ['features', 'pricing', 'faq'],
    },
  },
  'how-it-works': {
    en: {
      title: 'How to use AutoLinky: from CV to applications',
      description: 'Get started with AutoLinky on the web or Android: create an account, upload your CV, connect Gmail, and choose how to apply.',
      eyebrow: 'How it works',
      heading: 'From your CV to a clearer job search in four steps.',
      intro: 'AutoLinky is designed to reduce the repetitive work of looking for and applying to jobs. Start here on the web, or use the Android app with the same account.',
      sections: [
        { heading: '1. Create your account', paragraphs: ['Create your account on the website and continue with Google. Use AutoLinky in your browser or download the Android app with the same account. The app asks for the permissions it needs when a feature uses them.'] },
        { heading: '2. Upload your CV and review matches', paragraphs: ['Add a PDF or Word CV. AutoLinky reads your experience and skills, then compares your profile with collected job posts. Review the match explanation and the original job details before acting.'] },
        { heading: '3. Connect Gmail for email applications', paragraphs: ['If you want to send CVs by email, connect the Gmail address you want recruiters to see, following the in-app steps. AutoLinky checks the connection. You can disconnect it later in Settings.'] },
        { heading: '4. Apply manually or turn on Auto Apply', paragraphs: ['Use Send my CV to inspect and edit a cover letter before sending an email application. For other methods, open the WhatsApp chat, form, or site and complete the application there. Auto Apply can send eligible email applications on the server within the limits you choose.'] },
      ],
      answerHeading: 'Do I have to connect Gmail to use AutoLinky?',
      answer: 'No. You can review matched jobs and open non-email application methods without connecting Gmail. Gmail is needed when you want AutoLinky to send CVs by email.',
      related: ['features', 'auto-apply', 'faq'],
    },
    ar: {
      title: 'طريقة استخدام AutoLinky من السيرة الذاتية إلى التقديم',
      description: 'ابدأ مع AutoLinky على أندرويد بأربع خطوات: التثبيت، رفع السيرة الذاتية، ربط Gmail، واختيار طريقة التقديم.',
      eyebrow: 'طريقة العمل',
      heading: 'من سيرتك الذاتية إلى بحث أوضح عن الوظائف في أربع خطوات.',
      intro: 'صُمم AutoLinky لتقليل العمل المتكرر عند البحث عن الوظائف والتقديم لها. ابدأ هنا على الويب أو استخدم تطبيق أندرويد بالحساب نفسه.',
      sections: [
        { heading: '1. ثبّت التطبيق وسجّل الدخول', paragraphs: ['حمّل ملف أندرويد الحالي وتابع باستخدام Google لإنشاء حسابك أو الدخول إليه. يطلب التطبيق الأذونات اللازمة عندما تحتاج إليها إحدى المميزات.'] },
        { heading: '2. ارفع سيرتك وراجع الوظائف', paragraphs: ['أضف سيرة ذاتية PDF أو Word. يقرأ AutoLinky خبرتك ومهاراتك ويقارن ملفك بإعلانات الوظائف التي جُمعت. راجع شرح المطابقة وتفاصيل الإعلان الأصلي قبل اتخاذ القرار.'] },
        { heading: '3. اربط Gmail للتقديم بالبريد', paragraphs: ['إذا أردت إرسال السير الذاتية بالبريد، اربط عنوان Gmail الذي تريد أن يراه أصحاب العمل باتباع الخطوات داخل التطبيق. يتحقق AutoLinky من الاتصال، ويمكنك فصله لاحقًا من الإعدادات.'] },
        { heading: '4. قدّم بنفسك أو فعّل التقديم التلقائي', paragraphs: ['استخدم «أرسل سيرتي» لمراجعة خطاب التقديم وتعديله قبل إرسال البريد. وللطرق الأخرى افتح واتساب أو النموذج أو الموقع وأكمل التقديم هناك. ويمكن للتقديم التلقائي إرسال طلبات البريد المؤهلة على الخادم ضمن الحدود التي تختارها.'] },
      ],
      answerHeading: 'هل يجب ربط Gmail لاستخدام AutoLinky؟',
      answer: 'لا. يمكنك مراجعة الوظائف المناسبة وفتح طرق التقديم غير البريدية دون ربط Gmail. تحتاج إلى Gmail عندما تريد من AutoLinky إرسال السير الذاتية بالبريد.',
      related: ['features', 'auto-apply', 'faq'],
    },
  },
  pricing: {
    en: {
      title: 'AutoLinky pricing: free applications and Pro',
      description: 'Start with 20 free email applications. Learn what the free and Pro plans include and how to ask about a current Pro price.',
      eyebrow: 'Pricing',
      heading: 'Start with 20 email applications at no cost.',
      intro: 'The free plan includes 20 email applications in total, whether you send them manually or with Auto Apply. You can explore matched jobs and other application methods while deciding whether Pro is right for you.',
      sections: [
        { heading: 'Free', paragraphs: ['The free plan includes CV matching, job details, ways to apply, an Applied tracker, cover letters, and up to 20 sent email applications. The email allowance is shared between Send my CV and Auto Apply. You do not need a credit card to start.'] },
        { heading: 'Pro', paragraphs: ['Pro removes the 20-email plan allowance while your subscription is active. Your daily and Gmail sending limits still apply, so “unlimited” describes the subscription allowance, not unrestricted email volume.', 'Ask AutoLinky on WhatsApp for the current Pro price and term. We do not publish a price here until it can be kept accurate.'] },
        { heading: 'What happens when the free allowance ends?', paragraphs: ['Email sending pauses once the 20 included applications are used. The app shows an upgrade path. Other ways to review jobs and open external application methods remain available.'] },
      ],
      answerHeading: 'Is AutoLinky free?',
      answer: 'Yes. AutoLinky has a free plan with 20 email applications in total. Pro is available for an active subscription with no 20-email plan allowance; contact AutoLinky for current pricing.',
      related: ['billing', 'auto-apply', 'faq'],
    },
    ar: {
      title: 'أسعار AutoLinky: التقديم المجاني واشتراك Pro',
      description: 'ابدأ مع 20 طلب تقديم بالبريد مجانًا. تعرّف على مزايا الخطتين المجانية وPro وكيف تسأل عن سعر الاشتراك الحالي.',
      eyebrow: 'الأسعار',
      heading: 'ابدأ مع 20 طلب تقديم بالبريد مجانًا.',
      intro: 'تشمل الخطة المجانية 20 طلب تقديم بالبريد إجمالًا، سواء أرسلتها يدويًا أو عبر التقديم التلقائي. يمكنك استكشاف الوظائف وطرق التقديم الأخرى قبل اختيار Pro.',
      sections: [
        { heading: 'الخطة المجانية', paragraphs: ['تشمل مطابقة السيرة الذاتية وتفاصيل الوظائف وطرق التقديم ومتابعة الطلبات وخطابات التقديم وإرسال حتى 20 طلبًا بالبريد. يتشارك «أرسل سيرتي» والتقديم التلقائي هذا العدد. لا تحتاج إلى بطاقة ائتمان للبدء.'] },
        { heading: 'خطة Pro', paragraphs: ['تزيل خطة Pro حد 20 رسالة الخاص بالخطة أثناء سريان الاشتراك. وتبقى الحدود اليومية وحدود Gmail سارية؛ فـ«غير محدود» يخص رصيد الخطة وليس حجم بريد بلا قيود.', 'اسأل AutoLinky على واتساب عن سعر Pro ومدته حاليًا. لا ننشر سعرًا هنا إلى أن نستطيع إبقاءه محدثًا.'] },
        { heading: 'ماذا يحدث بعد انتهاء الطلبات المجانية؟', paragraphs: ['يتوقف إرسال البريد بعد استخدام الطلبات العشرين المشمولة، ويعرض التطبيق طريقة الترقية. ويمكنك الاستمرار في مراجعة الوظائف وفتح طرق التقديم الخارجية.'] },
      ],
      answerHeading: 'هل AutoLinky مجاني؟',
      answer: 'نعم. تشمل الخطة المجانية 20 طلب تقديم بالبريد إجمالًا. توفر Pro اشتراكًا نشطًا دون حد 20 رسالة الخاص بالخطة؛ تواصل مع AutoLinky لمعرفة السعر الحالي.',
      related: ['billing', 'auto-apply', 'faq'],
    },
  },
  faq: {
    en: {
      title: 'AutoLinky FAQ: Gmail, Auto Apply, Android and pricing',
      description: 'Answers to common AutoLinky questions about the free plan, Gmail connection, automatic applications, Android downloads, and iPhone availability.',
      eyebrow: 'FAQ',
      heading: 'Answers before you download.',
      intro: 'These answers explain what AutoLinky does, what stays under your control, and what you need to start applying from the Android app.',
      questions: [
        ['Is AutoLinky free?', 'Yes. The free plan includes 20 email applications in total, sent manually or through Auto Apply. Ask about Pro if you need more.'],
        ['Do I need Gmail to find jobs?', 'No. You can review matched jobs and use non-email application routes without Gmail. Connecting Gmail is required to send a CV by email or enable email Auto Apply.'],
        ['Does AutoLinky ask for my Google password?', 'No. Email sending uses a separate, revocable access key. The server encrypts it, and you can revoke it in your Google account or disconnect Gmail in the app.'],
        ['Does Auto Apply send every job automatically?', 'No. It sends only eligible email jobs that meet your selected match and daily limits. WhatsApp, Easy Apply, forms, and company sites require your action.'],
        ['Can I edit a cover letter?', 'Yes. For a manual Send my CV application, you can review and edit the letter before sending. Auto Apply uses the prepared letter without that per-job review.'],
        ['How do I install and update the Android app?', 'Use the download button for the current APK, open the file, and allow installation if Android asks. The app can apply downloaded improvements when you next open it.'],
        ['Is there an iPhone app?', 'AutoLinky is available for Android now. Contact AutoLinky on WhatsApp if you want to hear about iPhone availability.'],
      ],
      related: ['how-it-works', 'features', 'pricing'],
    },
    ar: {
      title: 'أسئلة AutoLinky: Gmail والتقديم التلقائي وأندرويد والأسعار',
      description: 'إجابات عن الخطة المجانية وربط Gmail والتقديم التلقائي وتحميل أندرويد وتوفر نسخة آيفون.',
      eyebrow: 'الأسئلة الشائعة',
      heading: 'إجابات مهمة قبل التحميل.',
      intro: 'توضح هذه الإجابات ما يفعله AutoLinky، وما يبقى تحت تحكمك، وما تحتاجه لتبدأ التقديم من تطبيق أندرويد.',
      questions: [
        ['هل AutoLinky مجاني؟', 'نعم. تشمل الخطة المجانية 20 طلب تقديم بالبريد إجمالًا، يدويًا أو عبر التقديم التلقائي. اسأل عن Pro إذا احتجت إلى المزيد.'],
        ['هل أحتاج إلى Gmail للعثور على الوظائف؟', 'لا. يمكنك مراجعة الوظائف المناسبة واستخدام طرق التقديم غير البريدية دون Gmail. يلزم ربط Gmail لإرسال السيرة بالبريد أو تفعيل التقديم التلقائي بالبريد.'],
        ['هل يطلب AutoLinky كلمة مرور حساب Google؟', 'لا. يستخدم الإرسال مفتاح وصول منفصلًا يمكن إلغاؤه. يخزنه الخادم مشفرًا، ويمكنك إلغاؤه من حساب Google أو فصل Gmail من التطبيق.'],
        ['هل يرسل التقديم التلقائي لكل الوظائف؟', 'لا. يرسل فقط لوظائف البريد المؤهلة التي تستوفي درجة المطابقة والحد اليومي اللذين اخترتهما. وتتطلب واتساب وEasy Apply والنماذج ومواقع الشركات تدخلك.'],
        ['هل يمكنني تعديل خطاب التقديم؟', 'نعم. عند استخدام «أرسل سيرتي» يدويًا، يمكنك مراجعة الخطاب وتعديله قبل الإرسال. يستخدم التقديم التلقائي الخطاب الجاهز دون مراجعة كل وظيفة على حدة.'],
        ['كيف أثبت تطبيق أندرويد وأحصل على التحديثات؟', 'استخدم زر التحميل للحصول على ملف APK الحالي، وافتحه واسمح بالتثبيت إذا طلب أندرويد. يستطيع التطبيق تطبيق التحسينات المحمّلة عند فتحه لاحقًا.'],
        ['هل توجد نسخة آيفون؟', 'يتوفر AutoLinky على أندرويد حاليًا. تواصل معنا على واتساب إذا أردت معرفة أخبار نسخة آيفون.'],
      ],
      related: ['how-it-works', 'features', 'pricing'],
    },
  },
  ...LEGAL_PAGES,
};

export function pagePath(slug, lang) {
  return `${lang === 'ar' ? '/ar' : ''}/${slug ? `${slug}/` : ''}`;
}
