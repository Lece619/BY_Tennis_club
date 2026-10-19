-- 22단계: 모임 종류(kind)는 'regular' / 'flash' 두 값만 허용 (스크립트 삽입 방지)
-- schema21 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
alter table meetups drop constraint if exists meetups_kind_check;
alter table meetups add constraint meetups_kind_check check (kind in ('regular', 'flash'));
