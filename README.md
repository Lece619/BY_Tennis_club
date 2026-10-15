# BY 테니스 클럽 사이트

달력에서 정기 모임과 자유 모임을 만들고, 참가 신청과 복식 대진표, 결과 기록까지 되는 한 장짜리 웹 페이지입니다.

## 구성
- `index.html` : 페이지 전체 (화면 + 동작). 상단 `CLUB_NAME` 에서 모임 이름을 바꿀 수 있습니다.
- `schema.sql` : Supabase 테이블 생성 SQL (1단계)
- `schema2_auth.sql` : 카카오 로그인 + 관리자 권한 SQL (2단계)
- `schema3_admin_code.sql` : 관리자 코드 방식 SQL (3단계, 실행 전 코드 값 수정)
- `schema4_profile.sql` : 회원 프로필 항목(구력·성별) SQL (4단계)
- `schema5_guest_birth.sql` : 생년 + 게스트 등록 SQL (5단계)
- `schema6_display.sql` : 이름 표시 방식 설정 SQL (6단계)
- `schema7_create_rules.sql` : 모임 생성 규칙 SQL (7단계)
- `schema8_meetup_options.sql` : 장소 필수, 코트 수 선택, 인원 제한 없음 SQL (8단계)
- `schema9_nickname.sql` : 닉네임 중복 방지 SQL (9단계)
- `schema10_approval.sql` : 회원 승인 + 관리자 인증 버그 수정 SQL (10단계)
- `schema11_owner.sql` : 대표 역할, 대표 코드, 회원 삭제, 별 표시 SQL (11단계, 실행 전 대표 코드 수정)

## 처음 한 번 할 일
1. Supabase 대시보드 → 왼쪽 메뉴 **SQL Editor** → `schema.sql` 내용을 붙여넣고 **Run**
2. 같은 곳에서 `schema2_auth.sql`, 이어서 `schema3_admin_code.sql`, `schema4_profile.sql`, `schema5_guest_birth.sql`, `schema6_display.sql`, `schema7_create_rules.sql`, `schema8_meetup_options.sql`, `schema9_nickname.sql`, `schema10_approval.sql`, `schema11_owner.sql` 도 **Run** (3단계 파일 안의 관리자 코드를 먼저 원하는 값으로 바꾸세요)
3. Supabase → Authentication → Providers → Kakao 켜고 REST API 키와 클라이언트 시크릿 입력
4. 카카오 개발자 콘솔 → 플랫폼 키 → REST API 키 → 리다이렉트 URI에 `https://<프로젝트>.supabase.co/auth/v1/callback` 등록
5. 사이트에서 카카오 로그인 → 오른쪽 위 이름 → 내 정보 → **관리자 인증**에 코드 입력

## 게스트
카카오 계정이 없는 사람은 로그인 창의 "게스트로 참여"에서 이름과 전화번호로 등록합니다. 같은 이름과 번호로 다른 폰에서도 로그인됩니다.
이 기능을 쓰려면 Supabase → Authentication → Providers → Email 에서 **Confirm email 을 꺼야** 합니다.

## 가입 승인
새로 가입한 계정(카카오·게스트)은 '승인 대기' 상태입니다. 관리자가 하단 **관리** 탭에서 승인해야 모임 참가와 생성이 됩니다.

## 권한
- 로그인 없이: 일정과 참가자, 대진표 보기
- 게스트: 참가 신청과 취소, 내 정보 수정 (모임 만들기는 불가)
- 회원: 자유 모임 만들기, 참가 신청과 취소, 내 정보 수정
- 정기 모임 만들기: 관리자만
- 모임 주최자: 자기 모임 삭제, 참가자 빼기, 대진 생성, 점수 입력
- 관리자(여러 명): 모든 모임에 주최자 권한, 가입 승인, 회원·게스트 휴식 처리·삭제, 이름 표시 방식 설정
- 대표(한 명, 별 표시): 관리자 권한 + 관리자 지정·해제, 관리자 삭제, 대표 넘기기, 관리자 코드·대표 코드 변경. 관리자가 내 정보에서 대표 코드를 입력하면 대표가 됩니다.

## 공개 주소로 올리기 (GitHub Pages)
1. GitHub 에서 새 저장소 생성 (예: `tennis`)
2. 이 폴더의 `index.html` 을 업로드
3. 저장소 Settings → Pages → Branch 를 `main` 으로 선택 → Save
4. 잠시 뒤 `https://아이디.github.io/tennis/` 로 접속

## 참고
- 관리자을 SQL로 직접 지정하려면: `update profiles set role = 'admin' where name = '이름';`
- Supabase의 service_role 키는 절대 저장소나 페이지에 넣지 마세요.
