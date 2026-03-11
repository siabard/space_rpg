package space_rpg

import sdl "vendor:sdl2"

Dialog_System :: struct {
    is_active:     bool,
    text:          string,
    
    current_page:  int,
    visible_runes: f32,  // 시간(dt)에 따라 증가하는 글자 수 (실수형)
    speed:         f32,  // 초당 출력되는 글자 수 (예: 30.0)
    
    // UI 박스 영역
    bounds:        sdl.Rect,
}

// 대화 시작 함수
start_dialog :: proc(sys: ^Dialog_System, text: string) {
    sys.is_active = true
    sys.text = text
    sys.current_page = 0
    sys.visible_runes = 0.0
    sys.speed = 40.0 // 초당 40글자 출력
    
    // 대화창 위치 설정 (화면 하단)
    sys.bounds = sdl.Rect{x = 50, y = 400, w = 700, h = 150}
}

// 대화 시스템 업데이트 (입력 및 타이머 처리)
update_dialog :: proc(sys: ^Dialog_System, dt: f32, input: ^Input_Manager) {
    if !sys.is_active do return

    // 1. 타이머를 통한 글자 수 증가
    sys.visible_runes += sys.speed * dt

    // 2. 사용자 입력 처리 (엔터 키 또는 스페이스바)
    if input.keys_pressed[sdl.SCANCODE_RETURN] || input.keys_pressed[sdl.SCANCODE_SPACE] {
        // 임의의 큰 숫자를 기준으로 텍스트가 다 나왔는지 판별합니다.
        // (실제로는 draw_text에서 현재 페이지가 끝났는지 반환받는 것이 가장 정확합니다)
        if sys.visible_runes > 1000.0 {
            // 이미 글자가 다 나왔다면 다음 페이지로 넘어감
            sys.current_page += 1
            sys.visible_runes = 0.0
            
            // 임시 종료 조건: 페이지가 너무 많이 넘어가면 대화 종료
            // (실제 완성본에서는 draw_text의 반환값을 통해 텍스트 끝 도달 여부를 확인해야 합니다)
            if sys.current_page > 3 {
                sys.is_active = false
            }
        } else {
            // 글자가 출력되는 도중이었다면, 스킵하여 전체 글자를 한 번에 표시
            sys.visible_runes = 9999.0
        }
    }
}

render_dialog :: proc(sys: ^Dialog_System, renderer: ^sdl.Renderer, fonts: Font_Textures) {
    if !sys.is_active do return

    // 1. 대화창 배경 그리기 (반투명한 검은색 박스)
    sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.BLEND)
    sdl.SetRenderDrawColor(renderer, 10, 10, 30, 200) // 어두운 네이비색, 알파값 200
    sdl.RenderFillRect(renderer, &sys.bounds)

    // 2. 대화창 테두리 그리기 (흰색 선)
    sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)
    sdl.RenderDrawRect(renderer, &sys.bounds)
    
    // 다시 블렌드 모드 복구
    sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.NONE)

    // 3. 텍스트 렌더링 호출
    // 여백(Padding)을 15px 정도 줍니다.
    text_x := sys.bounds.x + 15
    text_y := sys.bounds.y + 15
    text_w := sys.bounds.w - 30
    text_h := sys.bounds.h - 30

    // f32 상태값을 int로 변환하여 넘김 (자연스러운 타이프라이터 효과)
    draw_text(
        renderer, fonts, 
        text_x, text_y, text_w, text_h, 
        sys.current_page, 
        int(sys.visible_runes), 
        sys.text
    )
}
