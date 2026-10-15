-- 4단계: 회원 프로필 항목(구력, 성별, 연령대) + 프로필 사진 https 보정
-- schema3 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

alter table profiles add column if not exists experience text;   -- '0-1' | '1-3' | '3-5' | '5+'
alter table profiles add column if not exists gender text;       -- 'm' | 'f'
alter table profiles add column if not exists age_group text;    -- '20' | '30' | '40' | '50' | '60'

-- 참가자 → 프로필 연결 (명단에 구력 표시용)
alter table participants drop constraint if exists participants_user_profile_fk;
alter table participants add constraint participants_user_profile_fk
  foreign key (user_id) references profiles(id) on delete cascade;

-- 카카오 프로필 사진이 http 로 오는 문제 보정
update profiles set avatar_url = replace(avatar_url, 'http://', 'https://') where avatar_url like 'http://%';

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := replace(coalesce(meta->>'avatar_url', meta->>'picture', ''), 'http://', 'https://');
begin
  insert into profiles (id, name, avatar_url, role)
  values (new.id, nm, nullif(av, ''), 'member')
  on conflict (id) do nothing;
  return new;
end $$;
