export const FILM_DURATION=24;
export const FILM_CHAPTERS={
  en:[
    {label:'The search',title:'Your next job.\nLess busywork.',body:'You bring the experience. The job search brings the tabs, the forms and the same details. Again.',detail:'Finding a role can mean sorting through job boards and repeating the same information in application after application.'},
    {label:'The repetition',title:'Another role.\nThe same routine.',body:'Find a job. Check the fit. Rewrite the letter. Repeat. There’s a better use of your time.',detail:'AutoLinky brings CV matching, prepared cover letters and application tracking into one connected search.'},
    {label:'Your experience',title:'Your experience.\nStart with you.',body:'Add your CV and set your preferences. Give your search a starting point that actually reflects your experience.',detail:'Keep your profile and CV up to date so your skills, experience and location can inform your matches.'},
    {label:'A better fit',title:'Less searching.\nA better fit.',body:'See matched roles, the skills you share and the original opportunity. Know why it fits before you apply.',detail:'Match scores help you compare opportunities; they are guidance, not a guarantee of a job or an interview.'},
    {label:'Your pace',title:'Keep it moving.\nKeep it yours.',body:'Review a letter and send. Or enable Auto Apply for eligible email jobs, using your Gmail and the limits you choose.',detail:'You set the minimum match, daily limit and sending pace. Jobs using other application routes still need your action.'},
    {label:'Your next move',title:'Less admin.\nMore possibility.',body:'One place to move from your experience to your next opportunity. Your search, with a little more room to breathe.',detail:'Start free on the web or Android. Your profile and tracked applications stay connected.'},
  ],
  ar:[
    {label:'البحث',title:'وظيفتك القادمة.\nبخطوات أقل تكرارًا.',body:'أنت تملك الخبرة. لكن البحث يأتي بعشرات الصفحات والنماذج ونفس التفاصيل. مرة بعد مرة.',detail:'قد يتطلب العثور على وظيفة تصفح منصات كثيرة وإعادة إدخال نفس المعلومات في كل طلب.'},
    {label:'التكرار',title:'فرصة جديدة.\nونفس الروتين.',body:'ابحث عن وظيفة. راجع مدى ملاءمتها. اكتب خطابًا آخر. وكرر. وقتك يستحق أكثر.',detail:'يجمع AutoLinky مطابقة السيرة وخطابات التقديم الجاهزة ومتابعة الطلبات في رحلة بحث واحدة.'},
    {label:'خبراتك',title:'ابدأ بما\nيميزك أنت.',body:'أضف سيرتك وحدد تفضيلاتك. امنح بحثك نقطة بداية تعكس خبراتك الفعلية.',detail:'حدّث ملفك وسيرتك لتساعد مهاراتك وخبراتك وموقعك في تحديد الوظائف المطابقة.'},
    {label:'الفرصة المناسبة',title:'بحث أقل.\nوفرص أقرب إليك.',body:'شاهد الوظائف المطابقة والمهارات المشتركة والإعلان الأصلي. اعرف لماذا تناسبك قبل التقديم.',detail:'تساعدك درجات المطابقة في مقارنة الفرص؛ وهي إرشادية ولا تضمن وظيفة أو مقابلة.'},
    {label:'وتيرتك',title:'واصل التقديم.\nوالقرار يبقى لك.',body:'راجع الخطاب وأرسله. أو فعّل التقديم التلقائي للوظائف المؤهلة عبر Gmail وبالحدود التي تختارها.',detail:'حدد أقل نسبة مطابقة والحد اليومي ووتيرة الإرسال. الوظائف بطرق تقديم أخرى تحتاج إلى تدخلك.'},
    {label:'خطوتك القادمة',title:'تفاصيل متكررة أقل.\nومجال أوسع للفرص.',body:'مكان واحد ينقلك من خبراتك إلى فرصتك القادمة. بحثك عن وظيفة، مع مساحة أكبر ليومك.',detail:'ابدأ مجانًا على الويب أو أندرويد. يبقى ملفك وطلباتك المسجلة متصلة.'},
  ],
};

export const clampProgress=value=>Math.max(0,Math.min(1,Number.isFinite(value)?value:0));
export const filmChapter=progress=>Math.min(5,Math.floor(clampProgress(progress)*6));

// A shared playhead drives both sides of the handoff, so scrolling backwards
// retraces exactly the same positions instead of starting another animation.
export function filmCopyLayers(progress,reduced=false){
  const active=filmChapter(progress),time=clampProgress(progress)*FILM_DURATION;
  const boundary=Math.round(time/4),window=.7,half=window/2,travel=14;
  const changing=!reduced&&boundary>0&&boundary<6&&Math.abs(time-boundary*4)<half;
  const phase=clampProgress((time-boundary*4+half)/window);
  const entering=phase>=.5,part=entering?(phase-.5)*2:phase*2,blend=part*part*(3-2*part);
  return Array.from({length:6},(_,index)=>{
    if(changing&&index===boundary-1)return {index,opacity:entering?0:1-blend,y:-travel*(entering?1:blend)};
    if(changing&&index===boundary)return {index,opacity:entering?blend:0,y:travel*(entering?1-blend:1)};
    return {index,opacity:index===active?1:0,y:reduced?0:index<active?-travel:index>active?travel:0};
  });
}
