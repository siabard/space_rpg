package space_rpg

import "core:fmt"
import "core:math/linalg"
import sdl "vendor:sdl2" 

import im "odin-imgui"
import im_sdl2 "odin-imgui/imgui_impl_sdl2"
import im_sdlrenderer2 "odin-imgui/imgui_impl_sdlrenderer2"

// 5. 로직 파이프라인 

update_physics :: proc(ctx: ^Game_Context, dt: f32) {
    // 배열을 처음부터 끝까지 순회 
    for &ship in ctx.ships {
	ship.position += ship.velocity * dt
    }
}



check_encounters :: proc(ctx: ^Game_Context) {

    // 항해 상태일 때만 인카운터(전투/조우)를 체크한다.
    #partial switch state in ctx.current_state {

	case State_Sailing: 
	player_ship := &ctx.ships[0] // 0 번 인덱스가 플레이어임 
	
	for ship in ctx.ships[1:] {

	    dist := linalg.distance(player_ship.position, ship.position)
	    if dist < 10.0 && ship.faction == .Pirate {
		// 해적과 충돌시 전투 상태로 즉시 전환
		fmt.println("해적과 조우했습니다! 전투 시작.")
		ctx.current_state = State_Combat{ target_ship_id = ship.id }
		return
	    }
	}
    }
}

main_loop :: proc(event: ^sdl.Event, ctx: ^Game_Context, dt: f32) -> bool {

    running := true
    // IMGUI 새 프레임 시작 
    im_sdlrenderer2.NewFrame()
    im_sdl2.NewFrame()
    im.NewFrame()

    // B. 게임 로직 업데이트 

    switch &state in ctx.current_state {
    case State_MainMenu:
	// -- 메인 메뉴 UI -- 
	im.SetNextWindowPos(im.Vec2{250, 200}, .Always, im.Vec2{0.5, 0.5})
	im.SetNextWindowSize(im.Vec2{300, 200}, .Always)

	// 타이틀 바나 크기 조절없는 순수 메뉴 창 
	window_flags := im.WindowFlags_NoDecoration
	im.Begin("Main Menu", nil, window_flags)
	// 텍스트 가운데 맞춤 
	im.SetCursorPosX(70)
	im.Text("SPACE RPG - Hey!")
	im.Spacing()
	im.Spacing()
	im.Spacing()

	// 시작버튼 
	im.SetCursorPosX(50)
	if im.Button("게임 시작 (Let's Go!)", im.Vec2{200, 40}) {

	    // 게임 시작 버튼을 누름 

	    // 플레이어 우주선 설정 (0 번 우주선)
	    append(&ctx.ships, Ship {
		id = 0,
		position = {400, 300},
		velocity = {50, 20}, 
		faction = .Player,
		max_hp = 100,
		hull_hp = 100,
	    })
	    ctx.current_state = State_Sailing {}
	}
	im.Spacing()

	// 종료 버튼 
	im.SetCursorPosX(50)
	if im.Button("게임 종료 (Exit)", im.Vec2{200, 40}) {
	    running = false
	}
	im.End()

	// 메인메뉴에서 ESC를 누르면 게임 종료 
	if ctx.input.keys_pressed[sdl.SCANCODE_ESCAPE] {
	    running = false
	}

    case State_Sailing:


	// 대화 모드 활성시 물리 연산과 다른 입력 차단 
	if ctx.dialog.is_active {
	    // ESC를 누르면 대화모드 종료 
	    if ctx.input.keys_pressed[sdl.SCANCODE_ESCAPE] {
		ctx.dialog.is_active = false
	    } else {
		// 아무키(any key)검출로직 
		any_pressed := false
		for key_pressed, scancode in ctx.input.keys_pressed {
		    if key_pressed && scancode != int(sdl.SCANCODE_ESCAPE) {
			any_pressed = true
			break;
		    }
		}

		if ctx.input.mouse_pressed[sdl.BUTTON_LEFT] { 
		    any_pressed = true
		}

		// 아무키나 눌렀을때 타이프라이터 제어 
		if any_pressed {
		    // 현재 페이지 글자가 충분히 많이 출력되면 다음 페이지 
		    if ctx.dialog.visible_runes > 1000.0 {
			ctx.dialog.current_page += 1
			ctx.dialog.visible_runes = 0.0

			// 임시: 3페이지 이상이면 대화 종료 
			if ctx.dialog.current_page > 2 {
			    ctx.dialog.is_active = false
			}
		    }  else {
			// 글자 타이핑 도중이면 스킵 
			ctx.dialog.visible_runes = 9999.0
		    }
		}
	    }

	    // 대화 모드 업데이트 타이머 
	    ctx.dialog.visible_runes += ctx.dialog.speed * dt
	} else if state.is_menu_open  {
	    // 대화창 없고 일시 정지 메뉴 열기 
	    // 항해중 ESC 를 누르면 메뉴 노출 
	    im.SetNextWindowPos(im.Vec2{10, 10}, .Always)
	    im.Begin("항해 UI", nil, im.WindowFlags_NoDecoration)
	    im.Text("항해 중 ... (Sailing)")
	    if im.Button("메인 메뉴로 돌아가기") {
		// 배열 삭제 
		clear(&ctx.ships)
		ctx.current_state = State_MainMenu {}
	    }
	    im.End()
	    
	    if ctx.input.keys_pressed[sdl.SCANCODE_ESCAPE] {
		state.is_menu_open = false
	    }
	    
	} else {
	    // T를 누르면 대화 스크립트 
	    if ctx.input.keys_pressed[sdl.SCANCODE_T] {
		long_text := "우주력 2026년...\n이곳은 은하계 외곽의 이름 모를 항성계다.\n\n우리는 이곳에서 새로운 자원을 찾고,\n우주 해적들의 위협으로부터 살아남아야 한다.\n\n가혹한 우주지만, 아직 희망은 있다...\n\n(아무 키나 눌러 다음으로)"
		start_dialog(&ctx.dialog, long_text)
	    }

	    // ESC키를 누르면 일시 정지한 메뉴 
	    if ctx.input.keys_pressed[sdl.SCANCODE_ESCAPE] {
		state.is_menu_open = true
	    }
	    // 순수 항해메뉴에서만 우주선 물리시스템 가동 
	    update_physics(ctx, dt)
	}


    case State_Docked:
	//

    case State_Combat:
	// 
    }

    // 렌더링 
    sdl.SetRenderDrawColor(ctx.renderer, 15, 15, 25, 255)
    sdl.RenderClear(ctx.renderer)


    // 함선 렌더링 
    if _, is_sailing := ctx.current_state.(State_Sailing); is_sailing {
	for &ship in ctx.ships {
	    if ship.faction == .Player {
		sdl.SetRenderDrawColor(ctx.renderer, 0, 255, 100, 255) // 민트색 (플레이어) 
	    } else {
		sdl.SetRenderDrawColor(ctx.renderer, 255, 50, 50, 255) // 붉은색 (적)
	    }

	    rect := sdl.Rect {
		x = i32(ship.position.x) - 10,
		y = i32(ship.position.y) - 10,
		w = 20, 
		h = 20,
	    }
	    sdl.RenderFillRect(ctx.renderer, &rect)
	}
	
    }

    // 대화 
    if ctx.dialog.is_active {
	render_dialog(&ctx.dialog, ctx.renderer, ctx.fonts)
    }

    

    // UI 렌더링 
    im.Render()
    im_sdlrenderer2.RenderDrawData(im.GetDrawData(), ctx.renderer)
    sdl.RenderPresent(ctx.renderer)

    return running
}


// 초기화 함수

// 메인 함수
main :: proc() {
    // 전역 게임 컨텍스트
    ctx: Game_Context


    init(&ctx)
    defer clean_up(&ctx)

    // 메인 루프 
    running := true 
    event: sdl.Event
    last_time := sdl.GetTicks() 

    for running {

	// ImGUI IO
	io := im.GetIO()

	// 이번 프레임의 Pressed/Released 리셋 
	reset_input_per_frame(&ctx.input)

	// Delta 계산 
	current_time := sdl.GetTicks()
	dt := f32(current_time - last_time) / 1000.0 
	last_time = current_time 

	// A. 입력 및 이벤트 추러 (Polling)
	for sdl.PollEvent(&event) {

	    // ImGui 에서 먼저 이벤트를 받아 상태를 갱신 
	    im_sdl2.ProcessEvent(&event)

	    // 이벤트 가로채기 
	    // ImGui 가 마우스를 점유 중인 경우에는 ImGui 가 이벤트를 먼저 처리함
	    if io.WantCaptureMouse {
		#partial switch event.type {
		    case .MOUSEBUTTONDOWN, .MOUSEBUTTONUP, .MOUSEMOTION, .MOUSEWHEEL:
		    continue
		}
	    } 


	    if io.WantCaptureKeyboard {

		#partial switch event.type {
		    case .KEYDOWN, .KEYUP, .TEXTINPUT:
		    continue
		}
	    }

	    #partial switch event.type {
		case .QUIT:
		running = false

		case .KEYDOWN:
		scancode := event.key.keysym.scancode
		if event.key.repeat == 0 {
		    ctx.input.keys_pressed[scancode] = true
		    ctx.input.keys_held[scancode] = true
		}

		case .KEYUP:
		scancode := event.key.keysym.scancode
		ctx.input.keys_released[scancode] = true
		ctx.input.keys_held[scancode] = false


		case .MOUSEBUTTONDOWN:
		btn := event.button.button 
		if btn < NUM_MOUSE_BUTTONS {
		    ctx.input.mouse_pressed[btn] = true
		    ctx.input.mouse_held[btn] = true
		}

		case .MOUSEBUTTONUP:
		btn := event.button.button
		if btn < NUM_MOUSE_BUTTONS {
		    ctx.input.mouse_released[btn] = true
		    ctx.input.mouse_held[btn] = false		    
		}
	    }
	}
	running = running && main_loop(&event, &ctx, dt)
    }
}
