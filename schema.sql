-- ═══════════════════════════════════════════════════════════════════
--  Cairo 3A Poultry — Fleet System v3.0 — Supabase Schema
--  انسخ هذا الكود كله في Supabase SQL Editor وشغّله
-- ═══════════════════════════════════════════════════════════════════

drop table if exists trips           cascade;
drop table if exists bookings        cascade;
drop table if exists vehicle_types   cascade;
drop table if exists routes          cascade;
drop table if exists employees       cascade;
drop table if exists sectors         cascade;
drop table if exists app_users       cascade;

-- ─── القطاعات ───────────────────────────────────────────────────────
create table sectors (
  id         serial primary key,
  name       text not null,
  color      text default '#c8102e',
  bg         text default '#fff1f2',
  ico        text default '🏢',
  depts      text[] default '{}',
  created_at timestamptz default now()
);

-- ─── الموظفون ────────────────────────────────────────────────────────
create table employees (
  code       text primary key,
  name       text not null,
  job        text default '',
  sector_id  integer references sectors(id),
  dept       text default '',
  created_at timestamptz default now()
);

-- ─── خطوط السير ─────────────────────────────────────────────────────
create table routes (
  id         serial primary key,
  name       text not null,
  from_city  text not null,
  to_city    text not null,
  created_at timestamptz default now()
);

-- ─── أنواع السيارات (مع سجل الأسعار) ───────────────────────────────
create table vehicle_types (
  id            serial primary key,
  name          text not null,
  capacity      integer not null,
  daily_cost    integer not null,
  icon          text default '🚗',
  price_history jsonb default '[]'::jsonb,
  created_at    timestamptz default now()
);

-- ─── طلبات الحجز ─────────────────────────────────────────────────────
create table bookings (
  id          serial primary key,
  ref         text unique,
  emp_code    text references employees(code) on delete cascade,
  route_id    integer references routes(id),
  depart_date date not null,
  return_date date not null,
  status      text default 'pending'
                check (status in ('pending','approved','rejected')),
  created_at  timestamptz default now()
);

-- ─── الرحلات (تعيين السيارات) ─────────────────────────────────────
create table trips (
  id               serial primary key,
  route_id         integer references routes(id),
  vehicle_type_id  integer references vehicle_types(id),
  depart_date      date not null,
  return_date      date not null,
  emp_codes        text[]  default '{}',
  num_vehicles     integer default 1,
  days             integer default 1,
  total_cost       integer default 0,
  cost_per_emp     integer default 0,
  notes            text    default '',
  created_at       timestamptz default now()
);

-- ─── المستخدمون ──────────────────────────────────────────────────────
create table app_users (
  id         serial primary key,
  username   text unique not null,
  password   text not null,
  role       text default 'employee' check (role in ('admin','employee')),
  emp_code   text references employees(code) on delete set null,
  created_at timestamptz default now()
);

-- ─── تعطيل RLS للتطوير ──────────────────────────────────────────────
alter table sectors       disable row level security;
alter table employees     disable row level security;
alter table routes        disable row level security;
alter table vehicle_types disable row level security;
alter table bookings      disable row level security;
alter table trips         disable row level security;
alter table app_users     disable row level security;

-- ═══════════════════════════════════════════════════════════════════
-- بيانات أولية — القطاعات
-- ═══════════════════════════════════════════════════════════════════
insert into sectors (name, color, bg, ico, depts) values
('قطاع التسمين',  '#dc2626', '#fef2f2', '🐔', array['إدارة المزارع','إدارة التغذية','إدارة الصحة الحيوانية','إدارة الإنتاج']),
('قطاع الأمهات',  '#ea580c', '#fff7ed', '🐓', array['إدارة القطعان','إدارة التربية','إدارة المزرعة','إدارة التلقيح']),
('قطاع التفريخ',  '#6b7280', '#f9fafb', '🥚', array['إدارة الحضانات','إدارة العمليات','إدارة الفرازة','إدارة الصيانة']),
('قطاع الأعلاف',  '#92400e', '#fef9c3', '🌾', array['إدارة المخازن','إدارة التصنيع','إدارة التوزيع','إدارة المشتريات']);

-- ═══════════════════════════════════════════════════════════════════
-- بيانات أولية — الموظفون
-- ═══════════════════════════════════════════════════════════════════
insert into employees (code, name, job, sector_id, dept) values
('E001', 'أحمد محمد علي',      'مهندس إنتاج',  1, 'إدارة المزارع'),
('E002', 'سارة خالد إبراهيم',  'فني تغذية',    1, 'إدارة التغذية'),
('E003', 'محمد عبدالله حسن',   'مشرف قطعان',   2, 'إدارة القطعان'),
('E004', 'فاطمة أحمد نور',     'مدير تفريخ',   3, 'إدارة الحضانات'),
('E005', 'عمر سعد الغامدي',    'مدير مخازن',   4, 'إدارة المخازن'),
('E006', 'نورة فهد السبيعي',   'فنية مختبر',   3, 'إدارة العمليات'),
('E007', 'خالد عبدالرحمن',     'مشرف تربية',   2, 'إدارة التربية'),
('E008', 'هند الزهراني',       'مهندسة أعلاف', 4, 'إدارة التصنيع'),
('E009', 'يوسف المطيري',       'مشرف صحة',     1, 'إدارة الصحة الحيوانية'),
('E010', 'مريم العتيبي',       'فنية تفريخ',   3, 'إدارة الفرازة');

-- ═══════════════════════════════════════════════════════════════════
-- بيانات أولية — خطوط السير
-- ═══════════════════════════════════════════════════════════════════
insert into routes (name, from_city, to_city) values
('الرياض ← جدة',             'الرياض', 'جدة'),
('الرياض ← الدمام',          'الرياض', 'الدمام'),
('الرياض ← مكة المكرمة',    'الرياض', 'مكة المكرمة'),
('جدة ← أبها',              'جدة',    'أبها'),
('الدمام ← المدينة المنورة', 'الدمام', 'المدينة المنورة');

-- ═══════════════════════════════════════════════════════════════════
-- بيانات أولية — أنواع السيارات
-- ═══════════════════════════════════════════════════════════════════
insert into vehicle_types (name, capacity, daily_cost, icon, price_history) values
('سيارة صالون', 7,  400,  '🚗', '[{"date":"2025-01-01","cost":400,"note":"سعر التأسيس"}]'::jsonb),
('ميني باص',   14,  700,  '🚌', '[{"date":"2025-01-01","cost":700,"note":"سعر التأسيس"}]'::jsonb),
('باص كبير',   30, 1100,  '🚍', '[{"date":"2025-01-01","cost":1100,"note":"سعر التأسيس"}]'::jsonb);

-- ═══════════════════════════════════════════════════════════════════
-- بيانات أولية — المستخدمون
-- ═══════════════════════════════════════════════════════════════════
insert into app_users (username, password, role, emp_code) values
('admin', 'admin123', 'admin',    null),
('E001',  'pass001',  'employee', 'E001'),
('E002',  'pass002',  'employee', 'E002'),
('E003',  'pass003',  'employee', 'E003'),
('E004',  'pass004',  'employee', 'E004'),
('E005',  'pass005',  'employee', 'E005'),
('E006',  'pass006',  'employee', 'E006'),
('E007',  'pass007',  'employee', 'E007'),
('E008',  'pass008',  'employee', 'E008'),
('E009',  'pass009',  'employee', 'E009'),
('E010',  'pass010',  'employee', 'E010');

-- ═══════════════════════════════════════════════════════════════════
-- تأكيد الإنشاء
-- ═══════════════════════════════════════════════════════════════════
select
  (select count(*) from sectors)       as القطاعات,
  (select count(*) from employees)     as الموظفون,
  (select count(*) from routes)        as خطوط_السير,
  (select count(*) from vehicle_types) as انواع_السيارات,
  (select count(*) from app_users)     as المستخدمون,
  'تم إعداد قاعدة البيانات بنجاح ✅'  as الحالة;
