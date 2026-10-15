-- 테니스 모임 사이트 테이블
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 Run 하세요.

create table if not exists meetups (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date date not null,
  start_time time,
  location text,
  courts int not null default 1,
  capacity int not null default 8,
  kind text not null default 'flash',   -- 'regular'(정기) | 'flash'(번개)
  note text,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists participants (
  id uuid primary key default gen_random_uuid(),
  meetup_id uuid not null references meetups(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (meetup_id, name)
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  meetup_id uuid not null references meetups(id) on delete cascade,
  round int not null,
  court int not null,
  team_a text[] not null,
  team_b text[] not null,
  score_a int,
  score_b int,
  created_at timestamptz not null default now()
);

create index if not exists meetups_date_idx on meetups(date);
create index if not exists participants_meetup_idx on participants(meetup_id);
create index if not exists matches_meetup_idx on matches(meetup_id);

-- 로그인 없이 쓰는 1차 버전: 누구나 읽고 쓸 수 있게 허용
alter table meetups enable row level security;
alter table participants enable row level security;
alter table matches enable row level security;

drop policy if exists "public all" on meetups;
drop policy if exists "public all" on participants;
drop policy if exists "public all" on matches;

create policy "public all" on meetups      for all using (true) with check (true);
create policy "public all" on participants for all using (true) with check (true);
create policy "public all" on matches      for all using (true) with check (true);
