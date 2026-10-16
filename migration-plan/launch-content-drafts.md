# Launch content drafts

Drafts for the texts and policy positions the roadmap lists as owner inputs, so none of them blocks the work. They are starting points for the owner to adjust, not final copy. Privacy and acceptable-use wording needs review by someone qualified for the jurisdictions involved; nothing here is legal advice. Placeholders are in square brackets.

## 1. In-app and website notices (English and Arabic)

The app already shows a bilingual service notice from the health endpoint (`SERVICE_NOTICE`); these texts use that channel.

| When | English | Arabic |
| --- | --- | --- |
| Four to two weeks before cutover | Autolinky is moving to a new, faster system on [date]. Please update the app to version [X] before then, or you will not be able to sign in. Your profile, CV and applications will be kept. | سيتم نقل Autolinky إلى نظام جديد وأسرع بتاريخ [التاريخ]. يرجى تحديث التطبيق إلى الإصدار [X] قبل هذا الموعد، وإلا لن تتمكن من تسجيل الدخول. سيتم الاحتفاظ بملفك الشخصي وسيرتك الذاتية وطلباتك. |
| Day before | Tomorrow, [date] from [time], Autolinky will be unavailable for about an hour while we move to the new system. Update the app now if you have not. | غداً [التاريخ] ابتداءً من [الوقت] سيكون Autolinky غير متاح لمدة ساعة تقريباً أثناء الانتقال إلى النظام الجديد. حدّث التطبيق الآن إن لم تفعل ذلك. |
| During the maintenance window | We are updating Autolinky. The app will be back shortly. Your data is safe. | نقوم حالياً بتحديث Autolinky وسيعود التطبيق للعمل قريباً. بياناتك محفوظة. |
| After cutover, shown to old builds | A new version of the app is required to continue. Please update, then sign in again with the same Google account or email. | يلزم تحديث التطبيق للمتابعة. يرجى التحديث ثم تسجيل الدخول مرة أخرى بنفس حساب Google أو البريد الإلكتروني. |
| After cutover, first sign-in on the new build | Welcome back. Your profile, CV and applications are all here. | أهلاً بعودتك. ملفك الشخصي وسيرتك الذاتية وطلباتك كلها موجودة. |

## 2. Account deletion screens

| Moment | English | Arabic |
| --- | --- | --- |
| Confirmation | Delete your account? This permanently removes your profile, CV and application history and cannot be undone. Some records may stay in backups until they expire ([N] days). | هل تريد حذف حسابك؟ سيتم حذف ملفك الشخصي وسيرتك الذاتية وسجل طلباتك نهائياً ولا يمكن التراجع عن ذلك. قد تبقى بعض السجلات في النسخ الاحتياطية حتى تنتهي مدتها ([N] يوماً). |
| Blocked (`deletion_blocked`) | You can't delete your account while an email is being sent. Please try again in a few minutes. | لا يمكن حذف حسابك أثناء إرسال بريد إلكتروني. يرجى المحاولة مرة أخرى بعد دقائق. |
| Done | Your account has been deleted. | تم حذف حسابك. |

## 3. Platform mail consent (Release 2)

| English | Arabic |
| --- | --- |
| Autolinky will send your applications from applications@auto-linky.com, using your name, with your CV attached. Replies go to your email address. Applications will not appear in your Gmail Sent folder. You can turn automatic applications off at any time; a message already accepted for delivery cannot be recalled. | سيرسل Autolinky طلباتك من applications@auto-linky.com باسمك ومعها سيرتك الذاتية. تصل الردود إلى بريدك الإلكتروني. لن تظهر الطلبات في مجلد المرسل في Gmail. يمكنك إيقاف التقديم التلقائي في أي وقت؛ أما الرسالة التي قُبلت للإرسال فلا يمكن سحبها. |

## 4. Privacy policy outline

Sections to write, with the facts the migration fixes:

1. **What we collect:** email address and sign-in provider (through Firebase Authentication, operated by Google); profile choices (roles, skills, countries, languages, titles); the CV file, its extracted text and links; applications you create, including the job snapshot and any letter; device token hashes; download statistics without names.
2. **Why:** to sign you in, match you to jobs, prepare letters and send applications you approve or enable.
3. **Who processes it:** Firebase/Google (identity); the hosting provider of the VPS; the hosted AI provider (CV text after contact details are redacted, and job text); the mail relay we operate (Release 2). State each provider's role.
4. **Third-party data we hold:** recruiter names, emails, phone numbers and profile links taken from public job posts, kept 14 days; the recipient address remains in your application history.
5. **Retention:** jobs and AI results 14 days; letters until sent or 14 days; CV, profile and applications until you delete your account; backups keep deleted data until they rotate ([N] days local, [M] days off-host).
6. **Your choices:** edit your profile, replace or delete your CV, turn off automatic applications, delete your account in the app, or ask us at [contact].
7. **Security:** encrypted transport, access limited to named operators, encrypted off-host backups, the admin console shows only the personal data needed for support and never CV files, letters or secrets.
8. **Data location:** the VPS region [region]; Firebase Authentication data is held by Google.
9. **Changes and contact:** how updates are announced; [contact email].

Jurisdiction-specific parts (legal bases, user rights, transfer rules, minimum age) are left for legal review.

## 5. Acceptable-use position for automated applications (Release 2)

Proposed position to adopt or adjust:

- Applications are sent only on the user's explicit action, or by automatic mode the user has explicitly consented to after seeing the sender and Reply-To.
- Messages go only to a contact address published by the job poster for applications, one recipient per message, plain text with the user's CV.
- Product limits stay as today: per-user daily and hourly limits, minimum gap between sends, 30 days between two emails to the same address, free-plan allowance; platform limits add a global daily cap and warm-up.
- Recipients can ask to stop by replying or writing to the operations mailbox; their address is added to the suppression list and is never mailed again.
- Bounces, complaints or abuse pause the affected user and, if serious, all platform sending through the kill switch.
- No bulk campaigns, no purchased lists, no attachments other than the user's CV.
- The operator reviews the operations mailbox [daily/weekly] and records suppressions.

## 6. Store and compliance checklist (verify against the current rules at submission)

- Apple: in-app account deletion; privacy policy URL; privacy nutrition labels (contact info, user content, identifiers, diagnostics as applicable to the SDKs actually included); Sign in with Apple or an accepted equivalent when third-party login is offered.
- Google Play: data safety form; account deletion path inside the app and a web page or URL for deletion requests; privacy policy URL.
- Web: privacy policy and deletion instructions linked from the sign-in screen.
- Firebase: authorized domains, the Hosting link domain for email links, and the Admin service account stored as a secret.

## 7. Operations mailbox response templates (Release 2)

| Situation | Reply |
| --- | --- |
| Recipient asks to stop | "Thank you. We have added your address to our do-not-contact list and you will not receive further messages from Autolinky users." |
| Recipient reports abuse | Acknowledge within [2] business days; pause the sending user; record the case; review before resuming. |
| Bounce notification | Record the address and reason; add hard bounces to the suppression list; do not resend. |
