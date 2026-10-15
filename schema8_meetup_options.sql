-- 8단계: 모임 옵션 — 장소 필수, 코트 수 선택, 모집 인원 제한 없음 허용
-- schema7 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

update meetups set location = '미정' where location is null;
alter table meetups alter column location set not null;

alter table meetups alter column courts drop not null;
alter table meetups alter column courts drop default;      -- null = 미정

alter table meetups alter column capacity drop not null;
alter table meetups alter column capacity drop default;    -- null = 제한 없음
