-- 20단계: 모임 댓글 + 공지사항
-- schema19 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 모임 댓글 (승인 회원·게스트 누구나 작성, 본인 또는 모임 관리자가 삭제)
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  meetup_id uuid not null references meetups(id) on delete cascade,
  user_id uuid references profiles(id) on delete set null,
  content text not null,
  created_at timestamptz not null default now()
);
create index if not exists comments_meetup_idx on comments(meetup_id, created_at);
alter table comments enable row level security;
drop policy if exists "comments read"   on comments;
drop policy if exists "comments insert" on comments;
drop policy if exists "comments delete" on comments;
create policy "comments read"   on comments for select using (true);
create policy "comments insert" on comments for insert to authenticated with check (user_id = auth.uid() and is_approved());
create policy "comments delete" on comments for delete to authenticated using (user_id = auth.uid() or can_manage(meetup_id));

-- 공지사항 (누구나 읽기, 관리자만 작성·수정·삭제)
create table if not exists notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  pinned boolean not null default false,
  user_id uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table notices enable row level security;
drop policy if exists "notices read"  on notices;
drop policy if exists "notices write" on notices;
create policy "notices read"  on notices for select using (true);
create policy "notices write" on notices for all to authenticated using (is_admin()) with check (is_admin());
