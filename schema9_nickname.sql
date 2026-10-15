-- 9단계: 닉네임 중복 방지
--   가입 시 중복이면 자동으로 숫자를 붙임 (홍길동 → 홍길동2). 대소문자·앞뒤 공백 무시.
-- schema8 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 중복 없는 닉네임 만들기
create or replace function unique_name(base text, self uuid default null) returns text
language plpgsql security definer set search_path = public as $$
declare
  b text := coalesce(nullif(trim(base), ''), '회원');
  cand text := b;
  n int := 2;
begin
  while exists (select 1 from profiles where lower(trim(name)) = lower(cand) and (self is null or id <> self)) loop
    cand := b || n;
    n := n + 1;
  end loop;
  return cand;
end $$;

-- 기존 중복 데이터 정리 (먼저 가입한 사람이 원래 이름 유지)
do $$
declare r record;
begin
  for r in
    select id from (
      select id, row_number() over (partition by lower(trim(name)) order by created_at) as rn from profiles
    ) t where rn > 1
  loop
    update profiles set name = unique_name(name, id) where id = r.id;
  end loop;
end $$;

-- 고유 규칙
create unique index if not exists profiles_name_unique_idx on profiles (lower(trim(name)));

-- 가입 트리거: 자동 번호 붙이기
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := replace(coalesce(meta->>'avatar_url', meta->>'picture', ''), 'http://', 'https://');
  guest boolean := coalesce((meta->>'guest')::boolean, false);
begin
  insert into profiles (id, name, avatar_url, role, is_guest)
  values (new.id, unique_name(nm), nullif(av, ''), 'member', guest)
  on conflict (id) do nothing;
  if guest then
    insert into profile_private (id, phone) values (new.id, meta->>'phone')
    on conflict (id) do update set phone = excluded.phone;
  end if;
  return new;
end $$;

-- 닉네임 사용 가능 여부 (내 정보에서 바꿀 때 확인용)
create or replace function name_available(candidate text) returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from profiles where lower(trim(name)) = lower(trim(candidate)) and id <> auth.uid()
  );
$$;
grant execute on function name_available(text) to authenticated;
