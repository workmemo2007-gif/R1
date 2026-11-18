import {
  ArrowLeft,
  Bell,
  BookOpen,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronLeft,
  Clock3,
  FileText,
  GraduationCap,
  Image as ImageIcon,
  LayoutDashboard,
  LibraryBig,
  LockKeyhole,
  Megaphone,
  Menu,
  MessagesSquare,
  MoreHorizontal,
  Paperclip,
  Plus,
  Search,
  Send,
  ShieldCheck,
  SlidersHorizontal,
  UserRound,
  UsersRound,
  X,
} from "lucide-react";
import { useMemo, useState } from "react";

type Tab = "home" | "library" | "chat" | "notifications" | "profile";

type LibraryFile = {
  title: string;
  subject: string;
  kind: string;
  size: string;
  tone: string;
};

const libraryFiles: LibraryFile[] = [
  { title: "ملزمة التشريح — الفصل الأول", subject: "التشريح", kind: "ملزمة", size: "4.8 MB", tone: "bg-[#e7f3f0] text-[#17665d]" },
  { title: "ملخص المحاضرة الثالثة", subject: "الكيمياء الحيوية", kind: "ملخص", size: "1.2 MB", tone: "bg-[#fff0da] text-[#a76019]" },
  { title: "محاضرات الأنسجة كاملة", subject: "الأنسجة", kind: "محاضرة", size: "12.6 MB", tone: "bg-[#e8eef8] text-[#285b9f]" },
  { title: "أسئلة مراجعة منتصف الفصل", subject: "الفيزيولوجي", kind: "أسئلة", size: "2.1 MB", tone: "bg-[#f0e9f7] text-[#79519c]" },
];

const navItems: { id: Tab; label: string; icon: typeof LayoutDashboard }[] = [
  { id: "home", label: "الرئيسية", icon: LayoutDashboard },
  { id: "library", label: "المكتبة", icon: LibraryBig },
  { id: "chat", label: "الدردشة", icon: MessagesSquare },
  { id: "notifications", label: "الإشعارات", icon: Bell },
  { id: "profile", label: "الحساب", icon: UserRound },
];

const tabForPath: Record<string, Tab> = {
  "/": "home",
  "/library": "library",
  "/chat": "chat",
  "/notifications": "notifications",
  "/profile": "profile",
};

function Avatar({ initials, className = "" }: { initials: string; className?: string }) {
  return (
    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-[#dcebe8] text-sm font-bold text-[#17665d] ${className}`}>
      {initials}
    </div>
  );
}

function SectionHeading({ eyebrow, title, action }: { eyebrow?: string; title: string; action?: string }) {
  return (
    <div className="mb-4 flex items-end justify-between gap-4">
      <div>
        {eyebrow && <p className="mb-1 text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">{eyebrow}</p>}
        <h2 className="text-xl font-extrabold tracking-tight text-[#102a43] sm:text-2xl">{title}</h2>
      </div>
      {action && <button className="text-sm font-bold text-[#17665d] transition hover:text-[#102a43]">{action}</button>}
    </div>
  );
}

function HomeOverview({ setTab, onApproval }: { setTab: (tab: Tab) => void; onApproval: () => void }) {
  return (
    <div className="space-y-8">
      <section className="relative overflow-hidden rounded-[2rem] bg-[#102a43] px-6 py-7 text-white shadow-[0_24px_70px_rgba(16,42,67,0.17)] sm:px-9 sm:py-9">
        <div className="absolute -left-10 -top-14 h-48 w-48 rounded-full bg-[#f0a35b]/20 blur-2xl" />
        <div className="absolute -bottom-24 right-20 h-64 w-64 rounded-full bg-[#3d8f87]/20 blur-3xl" />
        <div className="relative flex flex-col justify-between gap-8 lg:flex-row lg:items-end">
          <div className="max-w-xl">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-xs font-bold text-[#f7d2a5]">
              <span className="h-2 w-2 rounded-full bg-[#f0a35b]" /> نموذج تجريبي قابل للتعديل
            </div>
            <h1 className="max-w-lg text-3xl font-black leading-[1.15] tracking-tight sm:text-5xl">كل ما تحتاجه الشعبة، في مكان واحد.</h1>
            <p className="mt-4 max-w-lg text-sm leading-7 text-[#c8d8e5] sm:text-base">تابع جدولك، اكتشف آخر التبليغات، وشارك الملفات مع زملائك من مساحة واحدة هادئة وواضحة.</p>
            <div className="mt-6 flex flex-wrap gap-3">
              <button onClick={() => setTab("library")} className="inline-flex items-center gap-2 rounded-2xl bg-[#f0a35b] px-4 py-3 text-sm font-extrabold text-[#102a43] transition hover:-translate-y-0.5 hover:bg-[#ffc27f]">
                افتح المكتبة <ArrowLeft className="h-4 w-4" />
              </button>
              <button onClick={onApproval} className="inline-flex items-center gap-2 rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-sm font-bold text-white transition hover:bg-white/15">
                معاينة طلبات الموافقة <ShieldCheck className="h-4 w-4" />
              </button>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2 sm:gap-3 lg:min-w-[370px]">
            {[
              ["12", "ملفاً جديداً"],
              ["03", "تبليغات مهمة"],
              ["24/7", "مساحة الدردشة"],
            ].map(([value, label]) => (
              <div key={label} className="rounded-2xl border border-white/10 bg-white/[0.07] p-3 sm:p-4">
                <p className="text-xl font-black text-[#f7d2a5] sm:text-3xl">{value}</p>
                <p className="mt-1 text-[11px] leading-4 text-[#c8d8e5] sm:text-xs">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section>
        <SectionHeading eyebrow="الوصول السريع" title="ماذا تريد أن تفعل اليوم؟" />
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {[
            { icon: CalendarDays, title: "الجدول الدراسي", text: "محاضرتك القادمة 10:00 صباحاً", tab: "home" as Tab, tone: "bg-[#e8eef8] text-[#285b9f]" },
            { icon: BookOpen, title: "المكتبة", text: "آخر ملف: ملخص الكيمياء", tab: "library" as Tab, tone: "bg-[#e7f3f0] text-[#17665d]" },
            { icon: MessagesSquare, title: "الدردشة العامة", text: "18 شخصاً متصل الآن", tab: "chat" as Tab, tone: "bg-[#fff0da] text-[#a76019]" },
            { icon: Bell, title: "الإشعارات", text: "لديك إشعاران غير مقروءين", tab: "notifications" as Tab, tone: "bg-[#f0e9f7] text-[#79519c]" },
          ].map((item) => {
            const Icon = item.icon;
            return (
              <button key={item.title} onClick={() => setTab(item.tab)} className="group flex items-start gap-4 rounded-3xl border border-[#e6dfd5] bg-white p-4 text-right shadow-sm transition hover:-translate-y-1 hover:border-[#b8d7d1] hover:shadow-lg">
                <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl ${item.tone}`}><Icon className="h-5 w-5" /></span>
                <span className="min-w-0">
                  <span className="block font-extrabold text-[#102a43]">{item.title}</span>
                  <span className="mt-1 block truncate text-xs leading-5 text-[#748294]">{item.text}</span>
                </span>
                <ChevronLeft className="mr-auto mt-1 h-4 w-4 text-[#b4bdc5] transition group-hover:-translate-x-1 group-hover:text-[#17665d]" />
              </button>
            );
          })}
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
        <section className="rounded-[1.75rem] border border-[#e6dfd5] bg-white p-5 shadow-sm sm:p-6">
          <SectionHeading eyebrow="الآن" title="الجدول الدراسي" action="عرض الأسبوع" />
          <div className="space-y-3">
            {[
              { time: "10:00 — 11:30", subject: "التشريح العام", room: "قاعة 204", color: "bg-[#e7f3f0]" },
              { time: "12:00 — 13:30", subject: "الكيمياء الحيوية", room: "مختبر 2", color: "bg-[#fff0da]" },
              { time: "14:00 — 15:00", subject: "جلسة مراجعة حرة", room: "قاعة الأنشطة", color: "bg-[#e8eef8]" },
            ].map((item, index) => (
              <div key={item.subject} className={`flex items-center gap-4 rounded-2xl p-3 ${index === 0 ? "border border-[#b8d7d1] bg-[#f7fbfa]" : "bg-[#fbfaf8]"}`}>
                <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl ${item.color}`}><Clock3 className="h-5 w-5 text-[#17665d]" /></div>
                <div className="min-w-0 flex-1"><p className="font-extrabold text-[#102a43]">{item.subject}</p><p className="mt-1 text-xs text-[#748294]">{item.room}</p></div>
                <div className="text-left"><p className="text-sm font-bold text-[#102a43]">{item.time}</p>{index === 0 && <span className="mt-1 inline-flex text-[10px] font-black text-[#c6762a]">بعد 35 دقيقة</span>}</div>
              </div>
            ))}
          </div>
        </section>
        <section className="rounded-[1.75rem] border border-[#e6dfd5] bg-[#fffaf2] p-5 shadow-sm sm:p-6">
          <SectionHeading eyebrow="من الإدارة" title="آخر التبليغات" action="كل التبليغات" />
          <div className="space-y-4">
            <article className="border-r-2 border-[#f0a35b] pr-4"><div className="flex items-center justify-between gap-3"><h3 className="font-extrabold text-[#102a43]">تحديث موعد الاختبار النصفي</h3><span className="text-[10px] font-bold text-[#9ca7b1]">منذ ساعتين</span></div><p className="mt-2 text-sm leading-6 text-[#657587]">تم نقل موعد الاختبار إلى يوم الثلاثاء القادم. يرجى مراجعة الجدول.</p><button className="mt-3 text-xs font-extrabold text-[#a76019]">قراءة التبليغ ←</button></article>
            <article className="border-r-2 border-[#b8d7d1] pr-4"><div className="flex items-center justify-between gap-3"><h3 className="font-extrabold text-[#102a43]">فتح استقبال ملفات المكتبة</h3><span className="text-[10px] font-bold text-[#9ca7b1]">أمس</span></div><p className="mt-2 text-sm leading-6 text-[#657587]">يمكنكم الآن رفع ملخصاتكم للمراجعة والنشر العام.</p><button className="mt-3 text-xs font-extrabold text-[#17665d]">قراءة التبليغ ←</button></article>
          </div>
        </section>
      </div>
    </div>
  );
}

function LibraryView({ onAttach }: { onAttach?: (file: LibraryFile) => void }) {
  const [query, setQuery] = useState("");
  const filtered = useMemo(() => libraryFiles.filter((file) => `${file.title} ${file.subject} ${file.kind}`.includes(query)), [query]);
  return (
    <div className="space-y-7">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end"><div><p className="mb-1 text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">المكتبة التعليمية</p><h1 className="text-3xl font-black tracking-tight text-[#102a43]">اختر ما يساعدك اليوم</h1><p className="mt-2 text-sm text-[#748294]">ملفات مرتبة حسب المادة والنوع، جاهزة للقراءة والمشاركة.</p></div><button className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#102a43] px-4 py-3 text-sm font-bold text-white transition hover:bg-[#17665d]"><Plus className="h-4 w-4" /> رفع ملف للمراجعة</button></div>
      <div className="flex flex-col gap-3 rounded-3xl border border-[#e6dfd5] bg-white p-3 shadow-sm sm:flex-row"><div className="relative flex-1"><Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#9aa6b0]" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث عن ملف أو مادة..." className="h-11 w-full rounded-2xl bg-[#f8f4ed] pr-10 text-sm outline-none ring-0 placeholder:text-[#9aa6b0] focus:bg-[#f1eee8]" /></div><button className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[#e6dfd5] px-4 text-sm font-bold text-[#526273]"><SlidersHorizontal className="h-4 w-4" /> تصفية</button></div>
      <div className="flex gap-2 overflow-x-auto pb-1"><span className="shrink-0 rounded-full bg-[#102a43] px-4 py-2 text-xs font-bold text-white">كل المواد</span>{["التشريح", "الكيمياء الحيوية", "الأنسجة", "الفيزيولوجي"].map((subject) => <button key={subject} className="shrink-0 rounded-full border border-[#e6dfd5] bg-white px-4 py-2 text-xs font-bold text-[#748294] transition hover:border-[#b8d7d1] hover:text-[#17665d]">{subject}</button>)}</div>
      <div className="grid gap-4 md:grid-cols-2">{filtered.map((file) => <article key={file.title} className="group rounded-[1.6rem] border border-[#e6dfd5] bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:border-[#b8d7d1] hover:shadow-lg"><div className="flex items-start justify-between gap-3"><div className={`flex h-12 w-12 items-center justify-center rounded-2xl ${file.tone}`}><FileText className="h-5 w-5" /></div><button className="text-[#9aa6b0] transition hover:text-[#102a43]"><MoreHorizontal className="h-5 w-5" /></button></div><div className="mt-5"><div className="flex flex-wrap items-center gap-2"><span className={`rounded-full px-2.5 py-1 text-[10px] font-black ${file.tone}`}>{file.kind}</span><span className="text-[11px] font-bold text-[#9aa6b0]">{file.subject}</span></div><h3 className="mt-3 font-extrabold leading-6 text-[#102a43]">{file.title}</h3><p className="mt-2 text-xs text-[#9aa6b0]">أضيف منذ يومين · {file.size}</p></div><div className="mt-5 flex gap-2"><button className="flex-1 rounded-2xl bg-[#f8f4ed] px-3 py-2.5 text-xs font-extrabold text-[#526273] transition hover:bg-[#e7f3f0] hover:text-[#17665d]">فتح الملف</button>{onAttach && <button onClick={() => onAttach(file)} className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#e7f3f0] px-3 py-2.5 text-xs font-extrabold text-[#17665d] transition hover:bg-[#cfe7e2]"><Paperclip className="h-3.5 w-3.5" /> إرفاق</button>}</div></article>)}</div>
    </div>
  );
}

function ChatView({ onLibrary }: { onLibrary: () => void }) {
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState([{ from: "سارة أحمد", initials: "س", text: "هل نزل ملخص الكيمياء الحيوية الجديد؟", time: "10:42" }, { from: "أنت", initials: "م", text: "نعم، أرسلته في المكتبة قبل قليل.", time: "10:44" }]);
  const sendMessage = () => { if (!message.trim()) return; setMessages([...messages, { from: "أنت", initials: "م", text: message.trim(), time: "الآن" }]); setMessage(""); };
  return <div className="grid gap-5 xl:grid-cols-[1fr_300px]"><section className="flex min-h-[620px] flex-col overflow-hidden rounded-[1.8rem] border border-[#e6dfd5] bg-white shadow-sm"><div className="flex items-center justify-between border-b border-[#eee8df] p-5"><div className="flex items-center gap-3"><div className="relative flex h-12 w-12 items-center justify-center rounded-2xl bg-[#e7f3f0] text-[#17665d]"><UsersRound className="h-6 w-6" /><span className="absolute -bottom-1 -left-1 h-3.5 w-3.5 rounded-full border-2 border-white bg-[#57ae69]" /></div><div><h2 className="font-extrabold text-[#102a43]">دردشة الشعبة</h2><p className="mt-1 text-xs text-[#57ae69]">18 عضواً متصلاً الآن</p></div></div><button className="rounded-xl p-2 text-[#9aa6b0] hover:bg-[#f8f4ed]"><MoreHorizontal className="h-5 w-5" /></button></div><div className="flex-1 space-y-5 overflow-y-auto bg-[#fcfbf9] p-5">{messages.map((item, index) => <div key={`${item.time}-${index}`} className={`flex gap-3 ${item.from === "أنت" ? "flex-row-reverse" : ""}`}><Avatar initials={item.initials} className={item.from === "أنت" ? "bg-[#102a43] text-white" : ""} /><div className={`max-w-[78%] ${item.from === "أنت" ? "text-left" : ""}`}><div className={`mb-1 flex items-center gap-2 text-[11px] font-bold text-[#9aa6b0] ${item.from === "أنت" ? "justify-end" : ""}`}><span>{item.from}</span><span>{item.time}</span></div><div className={`rounded-2xl px-4 py-3 text-sm leading-6 ${item.from === "أنت" ? "rounded-tr-md bg-[#102a43] text-white" : "rounded-tl-md border border-[#e6dfd5] bg-white text-[#526273]"}`}>{item.text}</div></div></div>)}</div><div className="border-t border-[#eee8df] bg-white p-4"><div className="mb-3 flex items-center gap-2"><button onClick={onLibrary} className="inline-flex items-center gap-2 rounded-xl bg-[#e7f3f0] px-3 py-2 text-xs font-extrabold text-[#17665d] transition hover:bg-[#cfe7e2]"><BookOpen className="h-3.5 w-3.5" /> إرفاق من المكتبة</button><span className="text-[11px] text-[#9aa6b0]">الرسائل العامة تحذف بعد 24 ساعة</span></div><div className="flex items-center gap-2 rounded-2xl bg-[#f8f4ed] p-2"><button className="rounded-xl p-2 text-[#9aa6b0] hover:bg-white"><Paperclip className="h-4 w-4" /></button><input value={message} onChange={(event) => setMessage(event.target.value)} onKeyDown={(event) => event.key === "Enter" && sendMessage()} placeholder="اكتب رسالتك هنا..." className="min-w-0 flex-1 bg-transparent px-2 text-sm outline-none placeholder:text-[#9aa6b0]" /><button onClick={sendMessage} className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#102a43] text-white transition hover:bg-[#17665d]"><Send className="h-4 w-4" /></button></div></div></section><aside className="space-y-4"><div className="rounded-[1.6rem] bg-[#fffaf2] p-5"><p className="text-xs font-bold uppercase tracking-[0.16em] text-[#c6762a]">المحادثات الخاصة</p><h3 className="mt-2 font-extrabold text-[#102a43]">رسائل زملائك</h3><div className="mt-4 space-y-2"><button className="flex w-full items-center gap-3 rounded-2xl bg-white p-3 text-right shadow-sm"><Avatar initials="س" className="h-9 w-9 rounded-xl" /><span className="min-w-0 flex-1"><b className="block text-xs text-[#102a43]">سارة أحمد</b><small className="mt-1 block truncate text-[10px] text-[#9aa6b0]">أرسلت ملفاً من المكتبة</small></span><span className="h-2 w-2 rounded-full bg-[#f0a35b]" /></button><button className="flex w-full items-center gap-3 rounded-2xl p-3 text-right hover:bg-white"><Avatar initials="ع" className="h-9 w-9 rounded-xl bg-[#f0e9f7] text-[#79519c]" /><span className="min-w-0 flex-1"><b className="block text-xs text-[#102a43]">علي محمد</b><small className="mt-1 block truncate text-[10px] text-[#9aa6b0]">تمام، شكراً</small></span></button></div></div><div className="rounded-[1.6rem] border border-[#e6dfd5] bg-white p-5"><div className="flex items-center gap-3"><LockKeyhole className="h-5 w-5 text-[#17665d]" /><h3 className="font-extrabold text-[#102a43]">مساحتك الخاصة</h3></div><p className="mt-3 text-xs leading-6 text-[#748294]">الرسائل الخاصة لا يقرأها إلا أعضاء المحادثة، ويمكن مشاركة ملفات المكتبة المنشورة بأمان.</p></div></aside></div>;
}

function NotificationsView() { return <div className="space-y-7"><div><p className="mb-1 text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">مركز التنبيهات</p><h1 className="text-3xl font-black text-[#102a43]">ابقَ على اطلاع</h1></div><div className="space-y-3">{[{ icon: Megaphone, title: "تبليغ جديد من الإدارة", text: "تم تحديث موعد الاختبار النصفي.", time: "منذ ساعتين", tone: "bg-[#fff0da] text-[#a76019]", unread: true }, { icon: FileText, title: "تم نشر ملفك في المكتبة", text: "ملخص المحاضرة الثالثة أصبح متاحاً للجميع.", time: "أمس", tone: "bg-[#e7f3f0] text-[#17665d]", unread: true }, { icon: MessagesSquare, title: "رسالة خاصة جديدة", text: "سارة أحمد أرسلت لك ملفاً من المكتبة.", time: "أمس", tone: "bg-[#e8eef8] text-[#285b9f]", unread: false }].map((item) => { const Icon = item.icon; return <article key={item.title} className={`flex items-start gap-4 rounded-3xl border bg-white p-5 shadow-sm ${item.unread ? "border-[#b8d7d1]" : "border-[#e6dfd5]"}`}><div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl ${item.tone}`}><Icon className="h-5 w-5" /></div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center justify-between gap-2"><h3 className="font-extrabold text-[#102a43]">{item.title}</h3><span className="text-[11px] font-bold text-[#9aa6b0]">{item.time}</span></div><p className="mt-2 text-sm leading-6 text-[#748294]">{item.text}</p></div>{item.unread && <span className="mt-2 h-2.5 w-2.5 rounded-full bg-[#f0a35b]" />}</article> })}</div></div> }

function ProfileView({ onApproval }: { onApproval: () => void }) { return <div className="space-y-7"><div><p className="mb-1 text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">مساحتك</p><h1 className="text-3xl font-black text-[#102a43]">الحساب الشخصي</h1></div><div className="grid gap-5 lg:grid-cols-[0.8fr_1.2fr]"><section className="rounded-[1.8rem] bg-[#102a43] p-6 text-white shadow-lg"><div className="flex items-center gap-4"><Avatar initials="م" className="h-16 w-16 rounded-3xl bg-[#f0a35b] text-xl text-[#102a43]" /><div><h2 className="text-xl font-black">محمد علي</h2><p className="mt-1 text-sm text-[#c8d8e5]">طالب · شعبة الأحياء</p></div></div><div className="mt-8 grid grid-cols-2 gap-3"><div className="rounded-2xl bg-white/10 p-4"><p className="text-2xl font-black text-[#f7d2a5]">12</p><p className="mt-1 text-xs text-[#c8d8e5]">ملفاً مشاركاً</p></div><div className="rounded-2xl bg-white/10 p-4"><p className="text-2xl font-black text-[#f7d2a5]">08</p><p className="mt-1 text-xs text-[#c8d8e5]">محادثات خاصة</p></div></div><button className="mt-6 w-full rounded-2xl bg-white/10 px-4 py-3 text-sm font-bold text-white transition hover:bg-white/15">تعديل البيانات</button></section><section className="rounded-[1.8rem] border border-[#e6dfd5] bg-white p-6 shadow-sm"><div className="flex items-center justify-between"><div><h2 className="font-extrabold text-[#102a43]">بيانات الحساب</h2><p className="mt-1 text-xs text-[#9aa6b0]">آخر تحديث منذ 3 أيام</p></div><button className="rounded-xl p-2 text-[#9aa6b0] hover:bg-[#f8f4ed]"><MoreHorizontal className="h-5 w-5" /></button></div><div className="mt-6 grid gap-4 sm:grid-cols-2"><div className="rounded-2xl bg-[#fbfaf8] p-4"><p className="text-xs text-[#9aa6b0]">رقم الهاتف</p><p className="mt-2 font-bold text-[#102a43]">0770 ••• •• 60</p></div><div className="rounded-2xl bg-[#fbfaf8] p-4"><p className="text-xs text-[#9aa6b0]">حالة الحساب</p><p className="mt-2 inline-flex items-center gap-2 font-bold text-[#57ae69]"><span className="h-2 w-2 rounded-full bg-[#57ae69]" /> فعال</p></div><div className="rounded-2xl bg-[#fbfaf8] p-4"><p className="text-xs text-[#9aa6b0]">تاريخ التسجيل</p><p className="mt-2 font-bold text-[#102a43]">12 سبتمبر 2026</p></div><div className="rounded-2xl bg-[#fbfaf8] p-4"><p className="text-xs text-[#9aa6b0]">آخر دخول</p><p className="mt-2 font-bold text-[#102a43]">اليوم، 09:42</p></div></div><div className="mt-5 flex flex-wrap gap-2"><span className="rounded-full bg-[#e7f3f0] px-3 py-1.5 text-xs font-bold text-[#17665d]">الدردشة العامة</span><span className="rounded-full bg-[#e7f3f0] px-3 py-1.5 text-xs font-bold text-[#17665d]">الرسائل الخاصة</span><span className="rounded-full bg-[#e7f3f0] px-3 py-1.5 text-xs font-bold text-[#17665d]">رفع الملفات</span></div></section></div><section className="rounded-[1.8rem] border border-[#eadbc8] bg-[#fffaf2] p-6"><div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"><div className="flex items-start gap-4"><div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#f0a35b]/20 text-[#a76019]"><ShieldCheck className="h-5 w-5" /></div><div><h2 className="font-extrabold text-[#102a43]">لوحة الممثل التجريبية</h2><p className="mt-1 text-sm leading-6 text-[#748294]">استعرض تجربة الموافقة على الحسابات وإدارة البطاقة الجامعية والصلاحيات.</p></div></div><button onClick={onApproval} className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#a76019] px-4 py-3 text-sm font-bold text-white transition hover:bg-[#8e4e13]">فتح لوحة الموافقة <ArrowLeft className="h-4 w-4" /></button></div></section></div> }

function RegistrationModal({ onClose }: { onClose: () => void }) { return <div className="fixed inset-0 z-50 flex items-end justify-center bg-[#102a43]/50 p-0 backdrop-blur-sm sm:items-center sm:p-6"><div className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-t-[2rem] bg-white p-6 shadow-2xl sm:rounded-[2rem] sm:p-8"><div className="flex items-start justify-between gap-4"><div><p className="text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">تجربة التسجيل</p><h2 className="mt-2 text-2xl font-black text-[#102a43]">أنشئ حسابك في ممثلي</h2><p className="mt-2 text-sm leading-6 text-[#748294]">هذه شاشة تجريبية. بعد البرمجة ستُرسل البيانات إلى الإدارة للموافقة، باستثناء كلمة المرور.</p></div><button onClick={onClose} className="rounded-xl p-2 text-[#9aa6b0] hover:bg-[#f8f4ed]"><X className="h-5 w-5" /></button></div><div className="mt-7 grid gap-4 sm:grid-cols-2"><label className="text-sm font-bold text-[#526273]">الاسم الكامل<input className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd5] bg-[#fbfaf8] px-4 text-sm outline-none focus:border-[#b8d7d1]" placeholder="مثال: محمد علي" /></label><label className="text-sm font-bold text-[#526273]">رقم الهاتف<input className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd5] bg-[#fbfaf8] px-4 text-left text-sm outline-none focus:border-[#b8d7d1]" placeholder="0770 000 0000" /></label><label className="text-sm font-bold text-[#526273]">كلمة المرور<input type="password" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd5] bg-[#fbfaf8] px-4 text-sm outline-none focus:border-[#b8d7d1]" placeholder="••••••••" /></label><label className="text-sm font-bold text-[#526273]">تأكيد كلمة المرور<input type="password" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd5] bg-[#fbfaf8] px-4 text-sm outline-none focus:border-[#b8d7d1]" placeholder="••••••••" /></label></div><div className="mt-4 grid gap-4 sm:grid-cols-2"><button className="flex min-h-28 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-[#b8d7d1] bg-[#f7fbfa] text-sm font-bold text-[#17665d]"><ImageIcon className="h-6 w-6" /> أضف الصورة الشخصية <span className="text-[10px] font-normal text-[#9aa6b0]">PNG أو JPG · حتى 5MB</span></button><button className="flex min-h-28 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-[#e8c99f] bg-[#fffaf2] text-sm font-bold text-[#a76019]"><GraduationCap className="h-6 w-6" /> أضف البطاقة الجامعية <span className="text-[10px] font-normal text-[#9aa6b0]">ستظهر للموافقين فقط</span></button></div><div className="mt-5 flex items-start gap-3 rounded-2xl bg-[#f8f4ed] p-4"><LockKeyhole className="mt-0.5 h-4 w-4 shrink-0 text-[#17665d]" /><p className="text-xs leading-5 text-[#748294]">كلمة المرور تُحفظ داخل Supabase Auth ولا تُرسل إلى الإدارة. الإدارة تراجع الاسم والرقم والصورة والبطاقة فقط.</p></div><button onClick={onClose} className="mt-6 w-full rounded-2xl bg-[#102a43] px-4 py-3.5 text-sm font-extrabold text-white transition hover:bg-[#17665d]">إرسال طلب التسجيل التجريبي</button></div></div> }

function ApprovalModal({ onClose }: { onClose: () => void }) { return <div className="fixed inset-0 z-50 flex items-end justify-center bg-[#102a43]/50 p-0 backdrop-blur-sm sm:items-center sm:p-6"><div className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-t-[2rem] bg-white p-6 shadow-2xl sm:rounded-[2rem] sm:p-8"><div className="flex items-start justify-between gap-4"><div><p className="text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">إدارة الحسابات</p><h2 className="mt-2 text-2xl font-black text-[#102a43]">طلبات بانتظار الموافقة</h2><p className="mt-2 text-sm leading-6 text-[#748294]">معاينة للبيانات التي تصل للموافق. كلمة المرور لا تظهر هنا.</p></div><button onClick={onClose} className="rounded-xl p-2 text-[#9aa6b0] hover:bg-[#f8f4ed]"><X className="h-5 w-5" /></button></div><div className="mt-6 rounded-3xl border border-[#e6dfd5] bg-[#fcfbf9] p-4 sm:p-5"><div className="flex flex-col gap-5 sm:flex-row"><div className="flex h-28 w-24 shrink-0 items-end justify-center rounded-2xl bg-[#dcebe8] pb-3 text-3xl font-black text-[#17665d]">م</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-start justify-between gap-3"><div><h3 className="text-xl font-black text-[#102a43]">محمد علي حسن</h3><p className="mt-1 text-sm text-[#748294]">طالب · مقدم منذ 12 دقيقة</p></div><span className="rounded-full bg-[#fff0da] px-3 py-1.5 text-xs font-black text-[#a76019]">قيد المراجعة</span></div><div className="mt-5 grid gap-3 sm:grid-cols-3"><div className="rounded-2xl bg-white p-3"><p className="text-[10px] text-[#9aa6b0]">رقم الهاتف</p><p className="mt-1 text-sm font-bold text-[#102a43]">0770 123 4567</p></div><div className="rounded-2xl bg-white p-3"><p className="text-[10px] text-[#9aa6b0]">الصورة الشخصية</p><p className="mt-1 text-sm font-bold text-[#17665d]">تم الإرفاق ✓</p></div><div className="rounded-2xl bg-white p-3"><p className="text-[10px] text-[#9aa6b0]">البطاقة الجامعية</p><p className="mt-1 text-sm font-bold text-[#17665d]">عرض البطاقة ↗</p></div></div></div></div><div className="mt-5 flex flex-col gap-2 border-t border-[#eee8df] pt-4 sm:flex-row sm:justify-end"><button onClick={onClose} className="rounded-2xl border border-[#f0c0bd] px-5 py-3 text-sm font-extrabold text-[#b2544f] transition hover:bg-[#fff5f4]">رفض الطلب</button><button onClick={onClose} className="rounded-2xl bg-[#17665d] px-5 py-3 text-sm font-extrabold text-white transition hover:bg-[#105149]"><Check className="ml-1 inline h-4 w-4" /> قبول الحساب</button></div></div><div className="mt-4 flex items-center gap-2 rounded-2xl bg-[#f8f4ed] p-4 text-xs leading-5 text-[#748294]"><ShieldCheck className="h-4 w-4 shrink-0 text-[#17665d]" /> المعلومات المعروضة للموافق: الاسم، الرقم، الصورة، البطاقة، وحالة الطلب. لا يتم عرض كلمة المرور.</div></div></div> }

function LibraryPicker({ onClose, onSelect }: { onClose: () => void; onSelect: (file: LibraryFile) => void }) { return <div className="fixed inset-0 z-50 flex items-end justify-center bg-[#102a43]/45 p-0 backdrop-blur-sm sm:items-center sm:p-6"><div className="max-h-[88vh] w-full max-w-xl overflow-y-auto rounded-t-[2rem] bg-white p-6 shadow-2xl sm:rounded-[2rem] sm:p-7"><div className="flex items-start justify-between"><div><p className="text-xs font-bold uppercase tracking-[0.18em] text-[#c6762a]">إرفاق من المكتبة</p><h2 className="mt-2 text-2xl font-black text-[#102a43]">اختر ملفاً لإرساله</h2><p className="mt-2 text-sm text-[#748294]">تظهر هنا الملفات المنشورة فقط.</p></div><button onClick={onClose} className="rounded-xl p-2 text-[#9aa6b0] hover:bg-[#f8f4ed]"><X className="h-5 w-5" /></button></div><div className="relative mt-5"><Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#9aa6b0]" /><input placeholder="ابحث باسم الملف..." className="h-11 w-full rounded-2xl bg-[#f8f4ed] pr-10 text-sm outline-none" /></div><div className="mt-4 space-y-2">{libraryFiles.slice(0, 3).map((file) => <button key={file.title} onClick={() => onSelect(file)} className="flex w-full items-center gap-3 rounded-2xl border border-[#e6dfd5] p-3 text-right transition hover:border-[#b8d7d1] hover:bg-[#f7fbfa]"><div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${file.tone}`}><FileText className="h-4 w-4" /></div><span className="min-w-0 flex-1"><b className="block truncate text-sm text-[#102a43]">{file.title}</b><small className="mt-1 block text-[11px] text-[#9aa6b0]">{file.subject} · {file.kind} · {file.size}</small></span><Paperclip className="h-4 w-4 text-[#17665d]" /></button>)}</div></div></div> }

export default function Home() {
  const initialPath = typeof window === "undefined" ? "/" : window.location.pathname.replace(/\/$/, "") || "/";
  const [activeTab, setActiveTab] = useState<Tab>(tabForPath[initialPath] ?? "home");
  const [mobileMenu, setMobileMenu] = useState(false);
  const [registrationOpen, setRegistrationOpen] = useState(false);
  const [approvalOpen, setApprovalOpen] = useState(false);
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [attachedFile, setAttachedFile] = useState<LibraryFile | null>(null);

  const selectTab = (tab: Tab) => { setActiveTab(tab); setMobileMenu(false); };
  const pageTitle = navItems.find((item) => item.id === activeTab)?.label ?? "الرئيسية";

  return (
    <div dir="rtl" className="app-shell min-h-screen bg-[#f8f4ed] text-[#102a43]">
      <div className="mx-auto flex min-h-screen max-w-[1560px]">
        <aside className="hidden w-[270px] shrink-0 flex-col border-l border-[#e6dfd5] bg-[#fbfaf8] px-5 py-6 lg:flex">
          <div className="flex items-center gap-3 px-2"><div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#102a43] text-white shadow-lg shadow-[#102a43]/15"><GraduationCap className="h-6 w-6" /></div><div><p className="text-lg font-black tracking-tight text-[#102a43]">ممثلي</p><p className="text-[10px] font-bold tracking-[0.16em] text-[#c6762a]">مساحة الشعبة</p></div></div>
          <div className="mt-10 rounded-3xl bg-[#fffaf2] p-4"><div className="flex items-center gap-3"><Avatar initials="م" /><div className="min-w-0"><p className="truncate text-sm font-extrabold text-[#102a43]">محمد علي</p><p className="mt-1 text-[11px] text-[#9aa6b0]">طالب · فعال</p></div><span className="mr-auto h-2 w-2 rounded-full bg-[#57ae69]" /></div></div>
          <nav className="mt-8 space-y-1">{navItems.map((item) => { const Icon = item.icon; const active = activeTab === item.id; return <button key={item.id} onClick={() => selectTab(item.id)} className={`group flex w-full items-center gap-3 rounded-2xl px-4 py-3 text-right text-sm font-bold transition ${active ? "bg-[#102a43] text-white shadow-lg shadow-[#102a43]/10" : "text-[#748294] hover:bg-[#f1eee8] hover:text-[#102a43]"}`}><Icon className={`h-[18px] w-[18px] ${active ? "text-[#f0a35b]" : "text-[#9aa6b0] group-hover:text-[#17665d]"}`} />{item.label}{item.id === "notifications" && <span className={`mr-auto rounded-full px-2 py-0.5 text-[10px] ${active ? "bg-white/15 text-white" : "bg-[#f0a35b]/15 text-[#a76019]"}`}>2</span>}</button>; })}</nav>
          <div className="mt-auto rounded-3xl border border-[#e6dfd5] bg-white p-4"><div className="flex items-center gap-2 text-[#17665d]"><SparklesIcon /><span className="text-xs font-extrabold">نموذج أولي</span></div><p className="mt-2 text-[11px] leading-5 text-[#9aa6b0]">الواجهة الحالية للاستعراض فقط، وسترتبط بـ Supabase بعد اعتماد التصميم.</p><button onClick={() => setRegistrationOpen(true)} className="mt-4 w-full rounded-xl bg-[#e7f3f0] px-3 py-2.5 text-xs font-extrabold text-[#17665d]">تجربة التسجيل</button></div>
        </aside>
        <main className="min-w-0 flex-1 pb-24 lg:pb-8">
          <header className="sticky top-0 z-20 border-b border-[#e6dfd5]/80 bg-[#f8f4ed]/90 px-4 py-4 backdrop-blur-xl sm:px-8 lg:px-10"><div className="mx-auto flex max-w-7xl items-center justify-between gap-4"><div className="flex items-center gap-3"><button onClick={() => setMobileMenu(!mobileMenu)} className="rounded-xl p-2 text-[#526273] hover:bg-white lg:hidden">{mobileMenu ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</button><div className="lg:hidden"><p className="text-base font-black text-[#102a43]">ممثلي</p><p className="text-[9px] font-bold tracking-[0.14em] text-[#c6762a]">مساحة الشعبة</p></div><div className="hidden lg:block"><p className="text-xs font-bold text-[#9aa6b0]">مساء الخير، محمد</p><h1 className="mt-1 text-xl font-black text-[#102a43]">{pageTitle}</h1></div></div><div className="flex items-center gap-2"><button onClick={() => setRegistrationOpen(true)} className="hidden items-center gap-2 rounded-xl border border-[#e6dfd5] bg-white px-3 py-2 text-xs font-bold text-[#526273] transition hover:border-[#b8d7d1] hover:text-[#17665d] sm:inline-flex"><Plus className="h-3.5 w-3.5" /> طلب تسجيل تجريبي</button><button onClick={() => setActiveTab("notifications")} className="relative rounded-xl bg-white p-2.5 text-[#526273] shadow-sm hover:text-[#17665d]"><Bell className="h-5 w-5" /><span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full border-2 border-[#f8f4ed] bg-[#f0a35b]" /></button><Avatar initials="م" className="h-9 w-9 rounded-xl" /></div></div>{mobileMenu && <nav className="mx-auto mt-3 grid max-w-7xl gap-1 rounded-2xl border border-[#e6dfd5] bg-white p-2 lg:hidden">{navItems.map((item) => { const Icon = item.icon; return <button key={item.id} onClick={() => selectTab(item.id)} className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-bold ${activeTab === item.id ? "bg-[#102a43] text-white" : "text-[#748294]"}`}><Icon className="h-4 w-4" />{item.label}</button>; })}</nav>}</header>
          <div className="mx-auto max-w-7xl px-4 py-7 sm:px-8 lg:px-10">{activeTab === "home" && <HomeOverview setTab={selectTab} onApproval={() => setApprovalOpen(true)} />}{activeTab === "library" && <LibraryView />}{activeTab === "chat" && <ChatView onLibrary={() => setLibraryOpen(true)} />}{activeTab === "notifications" && <NotificationsView />}{activeTab === "profile" && <ProfileView onApproval={() => setApprovalOpen(true)} />}</div>
        </main>
      </div>
      <nav className="fixed bottom-0 left-0 right-0 z-30 border-t border-[#e6dfd5] bg-[#fbfaf8]/95 px-2 py-2 backdrop-blur-xl lg:hidden"><div className="mx-auto flex max-w-md items-center justify-around">{navItems.map((item) => { const Icon = item.icon; const active = activeTab === item.id; return <button key={item.id} onClick={() => selectTab(item.id)} className={`relative flex min-w-[58px] flex-col items-center gap-1 rounded-xl px-2 py-1.5 text-[10px] font-bold ${active ? "text-[#102a43]" : "text-[#9aa6b0]"}`}><Icon className={`h-5 w-5 ${active ? "text-[#17665d]" : ""}`} />{item.label}{item.id === "notifications" && <span className="absolute right-2 top-0 h-2 w-2 rounded-full bg-[#f0a35b]" />}</button>; })}</div></nav>
      {registrationOpen && <RegistrationModal onClose={() => setRegistrationOpen(false)} />}
      {approvalOpen && <ApprovalModal onClose={() => setApprovalOpen(false)} />}
      {libraryOpen && <LibraryPicker onClose={() => setLibraryOpen(false)} onSelect={(file) => { setAttachedFile(file); setLibraryOpen(false); }} />}
      {attachedFile && <div className="fixed bottom-20 left-1/2 z-40 flex w-[calc(100%-2rem)] max-w-sm -translate-x-1/2 items-center gap-3 rounded-2xl border border-[#b8d7d1] bg-white p-3 shadow-xl lg:bottom-6"><div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#e7f3f0] text-[#17665d]"><Paperclip className="h-4 w-4" /></div><div className="min-w-0 flex-1"><p className="truncate text-xs font-extrabold text-[#102a43]">تم إرفاق الملف</p><p className="truncate text-[10px] text-[#9aa6b0]">{attachedFile.title}</p></div><button onClick={() => setAttachedFile(null)} className="rounded-lg p-1 text-[#9aa6b0] hover:bg-[#f8f4ed]"><X className="h-4 w-4" /></button></div>}
    </div>
  );
}

function SparklesIcon() { return <span className="relative inline-flex h-4 w-4"><span className="absolute right-0 top-0 h-2 w-2 rotate-45 rounded-[2px] bg-[#f0a35b]" /><span className="absolute bottom-0 left-0 h-1.5 w-1.5 rotate-45 rounded-[1px] bg-[#17665d]" /></span>; }
