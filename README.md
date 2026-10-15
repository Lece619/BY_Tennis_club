# BY 테니스 클럽 사이트

달력에서 정기 모임과 번개를 만들고, 참가 신청과 복식 대진표, 결과 기록까지 되는 한 장짜리 웹 페이지입니다.

## 구성
- `index.html` : 페이지 전체 (화면 + 동작). 상단 `CLUB_NAME` 에서 모임 이름을 바꿀 수 있습니다.
- `schema.sql` : Supabase 테이블 생성 SQL (1단계)
- `schema2_auth.sql` : 카카오 로그인 + 운영진 권한 SQL (2단계)
- `schema3_admin_code.sql` : 운영진 코드 방식 SQL (3단계, 실행 전 코드 값 수정)

## 처음 한 번 할 일
1. Supabase 대시보드 → 왼쪽 메뉴 **SQL Editor** → `schema.sql` 내용을 붙여넣고 **Run**
2. 같은 곳에서 `schema2_auth.sql`, 이어서 `schema3_admin_code.sql` 도 **Run** (3단계 파일 안의 운영진 코드를 먼저 원하는 값으로 바꾸세요)
3. Supabase → Authentication → Providers → Kakao 켜고 REST API 키와 클라이언트 시크릿 입력
4. 카카오 개발자 콘솔 → 플랫폼 키 → REST API 키 → 리다이렉트 URI에 `https://<프로젝트>.supabase.co/auth/v1/callback` 등록
5. 사이트에서 카카오 로그인 → 오른쪽 위 이름 → 내 정보 → **운영진 인증**에 코드 입력

## 권한
- 로그인 없이: 일정과 참가자, 대진표 보기
- 로그인 회원: 모임 만들기, 참가 신청과 취소, 내 이름 수정
- 모임 주최자: 자기 모임 삭제, 참가자 빼기, 대진 생성, 점수 입력
- 운영진: 모든 모임에 주최자 권한 + 홈의 회원 관리에서 운영진 지정·해제, 운영진 코드 변경

## 공개 주소로 올리기 (GitHub Pages)
1. GitHub 에서 새 저장소 생성 (예: `tennis`)
2. 이 폴더의 `index.html` 을 업로드
3. 저장소 Settings → Pages → Branch 를 `main` 으로 선택 → Save
4. 잠시 뒤 `https://아이디.github.io/tennis/` 로 접속

## 참고
- 운영진을 SQL로 직접 지정하려면: `update profiles set role = 'admin' where name = '이름';`
- Supabase의 service_role 키는 절대 저장소나 페이지에 넣지 마세요.
