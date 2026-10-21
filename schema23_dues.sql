-- 23단계: 회비 입금 계좌(club_settings 의 'dues_account')는 승인된 회원만 읽기
-- 회비 안내 글('dues')과 다른 설정은 지금처럼 누구나 읽기. 쓰기는 지금처럼 관리자 (schema19 정책 그대로)
-- schema22 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
drop policy if exists "settings read" on club_settings;
create policy "settings read" on club_settings for select using (key <> 'dues_account' or is_approved());
