-- 14단계: 주최자·참가자 이름을 프로필에서 가져오기, 대진표를 회원 ID 기준으로 저장
-- schema13 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
-- 주의: 기존 대진표(이름 기준 저장)는 삭제됩니다. 모임·참가자는 그대로 남습니다.

-- 주최자 → 프로필 연결
alter table meetups drop constraint if exists meetups_created_by_profile_fk;
alter table meetups add constraint meetups_created_by_profile_fk
  foreign key (created_by_id) references profiles(id) on delete set null;

-- 대진표: 이름(text[]) → 회원 ID(uuid[])
delete from matches;
alter table matches alter column team_a type uuid[] using '{}'::uuid[];
alter table matches alter column team_b type uuid[] using '{}'::uuid[];
