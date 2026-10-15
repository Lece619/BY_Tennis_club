-- 6단계: 운영진이 정하는 이름 표시 방식 (전체 회원에게 적용)
-- schema5 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

create table if not exists club_settings (
  key text primary key,
  value text not null
);
alter table club_settings enable row level security;

drop policy if exists "settings read"  on club_settings;
drop policy if exists "settings write" on club_settings;
create policy "settings read"  on club_settings for select using (true);
create policy "settings write" on club_settings for all to authenticated using (is_admin()) with check (is_admin());

-- display_format: 'name' (닉네임) | 'name_age' (닉네임/나이) | 'name_age_exp' (닉네임/나이/구력)
insert into club_settings (key, value) values ('display_format', 'name') on conflict (key) do nothing;
