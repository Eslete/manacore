# 자동화에 붙여 넣기

Cursor Automations 새 항목을 두 개 만든다. 지시문은 아래 파일을 **전체 복사**한다.

## 1. PR Godot parse

- 이름: `PR Godot parse`
- 설명: `When a pull request opens, parse the Godot project and comment PASS or FAIL.`
- 트리거: GitHub pull request opened, 저장소 `Eslete/manacore`
- 저장소: `Eslete/manacore`
- 도구: Comment on pull request 켜기. Slack 끄기.
- 지시문: `pr-godot-parse.md` 전체
- 설치 스크립트: 켜 두기 (Godot가 필요함)
- 저장 후 On

## 2. DESIGN drift

- 이름: `DESIGN drift`
- 설명: `Every day, check DESIGN.md against the code. Report only. Do not edit.`
- 트리거: 매일 09:00 (한국 시간이면 에디터 시간대를 한국으로)
- 저장소: `Eslete/manacore`, 브랜치 `master` (비어 있으면 직접 고른다)
- 도구: 전부 끄기. PR 생성도 끄기.
- 지시문: `design-drift.md` 전체
- 설치 스크립트: 꺼도 됨
- 저장 후 On
