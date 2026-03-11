package space_rpg

import sdl "vendor:sdl2"

// 1. 데이터 구조체 정의 (해시맵 대신 명시적 포인터 구조체 사용)
Font_Textures :: struct {
    ascii:  ^sdl.Texture,
    hangul: ^sdl.Texture,
}

// 2. ASCII 렌더링 로직 (포인터 접근으로 O(1) 처리)
draw_ascii :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, x, y: i32, r: rune) {
    code := i32(r)
    row := code / 16
    col := code % 16
    
    src := sdl.Rect{x = col * 8, y = row * 16, w = 8, h = 16}
    dst := sdl.Rect{x = x, y = y, w = 8, h = 16}
    
    sdl.RenderCopy(renderer, texture, &src, &dst)
}

// 3. 한글 조합형 렌더링 로직 (초/중/종성 오버레이)
draw_hangul :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, x, y: i32, r: rune) {
    jaso := build_jaso(r)
    bul := build_bul(jaso)

    dst := sdl.Rect{x = x, y = y, w = 16, h = 16}

    // 초성 (상단 1~8벌)
    cho_y := (bul.cho - 1) * 16
    cho_x := (jaso.cho - 1) * 16
    src_cho := sdl.Rect{x = cho_x, y = cho_y, w = 16, h = 16}
    sdl.RenderCopy(renderer, texture, &src_cho, &dst)

    // 중성 (상단 9~12벌)
    mid_y := ((bul.mid - 1) + 8) * 16
    mid_x := (jaso.mid - 1) * 16
    src_mid := sdl.Rect{x = mid_x, y = mid_y, w = 16, h = 16}
    sdl.RenderCopy(renderer, texture, &src_mid, &dst)

    // 종성 (상단 13~16벌, 종성이 있을 때만)
    if jaso.jong > 0 {
        jong_y := ((bul.jong - 1) + 12) * 16
        jong_x := jaso.jong * 16
        src_jong := sdl.Rect{x = jong_x, y = jong_y, w = 16, h = 16}
        sdl.RenderCopy(renderer, texture, &src_jong, &dst)
    }
}

// 4. 메인 텍스트 렌더링 및 페이징/랩핑 통합 엔진
draw_text :: proc(renderer: ^sdl.Renderer, fonts: Font_Textures, start_x, start_y, w, h: i32, target_page: int, max_runes: int, text: string) {
    cursor_x: i32 = 0
    cursor_y: i32 = 0
    current_page: int = 0
    line_height: i32 = 16

    runes_drawn: int = 0
    is_page_finished: bool = false // 현재 페이지의 텍스트 출력 여부 

    // Odin의 위력: string을 for 루프로 돌리면 UTF-8 바이트를 내부적으로 해독하여
    // 완벽한 유니코드 코드포인트(rune) 단위로 순회합니다. 메모리 할당이 전혀 없습니다!
    for r in text {
        // 1. 명시적 줄바꿈 처리
        if r == '\n' {
            cursor_x = 0
            cursor_y += line_height
            if cursor_y + line_height > h {
                current_page += 1
                cursor_y = 0
            }
            continue
        }

        // 2. 글자 종류 및 폭 판별 (ASCII 여부 검사)
        is_ascii := r >= 0x0020 && r <= 0x007E // 화면에 출력 가능한 ASCII 대역
        char_w: i32 = is_ascii ? 8 : 16

        // 3. 랩핑(Wrapping) 처리
        if cursor_x + char_w > w {
            cursor_x = 0
            cursor_y += line_height
            if cursor_y + line_height > h {
                current_page += 1
                cursor_y = 0
            }
        }

        // 4. 페이징 기반 타겟 렌더링 검사
        if current_page == target_page {
	    // 타이프라이터 로직 
	    if runes_drawn >= max_runes {
		break // 허용한 글자 수까지만 그리고 끝을 냄
	    }
            draw_x := start_x + cursor_x
            draw_y := start_y + cursor_y

            // 공백(Space)은 렌더링 콜을 생략하고 커서만 이동시키는 최적화
            if r != ' ' {
                if is_ascii {
                    draw_ascii(renderer, fonts.ascii, draw_x, draw_y, r)
                } else {
                    // 한글 영역 (U+AC00 ~ U+D7A3) 및 호환 자모 처리
                    draw_hangul(renderer, fonts.hangul, draw_x, draw_y, r)
                }
            }
	    runes_drawn += 1
        } else if current_page > target_page {
            // 그릴 필요 없는 다음 페이지 데이터는 조기 탈출하여 루프 종료
            break
        }

        // 5. 다음 글자를 위해 커서 이동
        cursor_x += char_w
    }
}
