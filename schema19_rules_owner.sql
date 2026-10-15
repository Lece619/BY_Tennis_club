-- 19단계: 회칙 수정은 대표만 (이름 표시 방식 등 다른 설정은 관리자도)
-- schema18 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

drop policy if exists "settings write" on club_settings;
create policy "settings write" on club_settings for all to authenticated
  using (is_admin() and (key <> 'rules' or is_owner()))
  with check (is_admin() and (key <> 'rules' or is_owner()));
