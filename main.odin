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

    switch state in ctx.current_state {
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

    case State_Sailing:
	update_physics(ctx, dt)

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

    case State_Docked:
	//

    case State_Combat:
	// 
    }

    // 렌더링 
    sdl.SetRenderDrawColor(ctx.renderer, 15, 15, 25, 255)
    sdl.RenderClear(ctx.renderer)


    // 함선 렌더링 
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

	// Delta 계산 
	current_time := sdl.GetTicks()
	dt := f32(current_time - last_time) / 1000.0 
	last_time = current_time 

	// A. 입력 및 이벤트 추러 (Polling)
	for sdl.PollEvent(&event) {
	    im_sdl2.ProcessEvent(&event)
	    #partial switch event.type {
		case .QUIT:
		running = false
	    }
	}
	running = running && main_loop(&event, &ctx, dt)
    }
}
