-- 5단계: 생년(두 자리) + 게스트 등록(이름·전화번호)
-- schema4 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
-- 그리고 Supabase > Authentication > Providers > Email 에서 "Confirm email" 을 끄세요. (게스트 등록에 필요)

alter table profiles add column if not exists birth_year int;            -- 예: 1988
alter table profiles add column if not exists is_guest boolean not null default false;
alter table profiles drop column if exists age_group;

-- 전화번호는 본인과 운영진만 볼 수 있게 별도 테이블
create table if not exists profile_private (
  id uuid primary key references profiles(id) on delete cascade,
  phone text
);
alter table profile_private enable row level security;
drop policy if exists "private read" on profile_private;
create policy "private read" on profile_private for select using (id = auth.uid() or is_admin());

-- 가입 트리거: 게스트 정보 반영
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := replace(coalesce(meta->>'avatar_url', meta->>'picture', ''), 'http://', 'https://');
  guest boolean := coalesce((meta->>'guest')::boolean, false);
begin
  insert into profiles (id, name, avatar_url, role, is_guest)
  values (new.id, nm, nullif(av, ''), 'member', guest)
  on conflict (id) do nothing;
  if guest then
    insert into profile_private (id, phone) values (new.id, meta->>'phone')
    on conflict (id) do update set phone = excluded.phone;
  end if;
  return new;
end $$;
