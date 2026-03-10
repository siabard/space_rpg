package space_rpg

import "core:fmt"
import "core:math/linalg"
import sdl "vendor:sdl2" 

import im "odin-imgui"
import im_sdl2 "odin-imgui/imgui_impl_sdl2"
import im_sdlrenderer2 "odin-imgui/imgui_impl_sdlrenderer2"

// 1. 기초 데이터 및 타입 알리아스 
Vec2 :: linalg.Vector2f32

Faction :: enum {
    Player,
    Pirate,
    Merchant,
    Navy,
}

Item_Type :: enum {
    Food,
    Water,
    Spice,
    Machinery,
    // 이후 필요 교역품 추가 

}

// 2. 핵심 엔터티 구조체 (AoS: Array of Structs)

Ship :: struct {
    id: u32,
    position: Vec2,
    velocity: Vec2,
    faction: Faction,
    hull_hp: f32,
    max_hp: f32,
    // 교역품 인벤토리 (고정 크기 배열로 메모리 할당/해제 비용 제거)
    cargo: [Item_Type]int,
}

Planet :: struct {
    id: u32,
    position: Vec2,
    name: string,
    // 행성별 교역품 시세 (0이하는 해당 상품 판매 안함)
    market_data: [Item_Type]f32,
}

// 3. 태그 유니온 (상태관리) 

UI_State :: union {
    State_MainMenu,
    State_Sailing,
    State_Docked,
    State_Combat,
}

State_MainMenu :: struct {}
State_Sailing :: struct {}
State_Docked :: struct { docked_planet_id: u32}
State_Combat :: struct { target_ship_id: u32, turn_timer: u32}

// 4. 전역 게임 컨텍스트 
// 모든 게임 상태를 한 곳에 모은다. 
Game_Context :: struct {
    ships: [dynamic]Ship, // 모든 우주선 (동적 배열)
    planets: [dynamic]Planet, // 모든 행성 
    current_state: UI_State, // 현재 게임 상태 (항해, 정박, 전투)
    next_entity_id: u32,
    
}

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

main_loop :: proc(renderer: ^sdl.Renderer, ctx: ^Game_Context, dt: f32) -> bool {

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
    sdl.SetRenderDrawColor(renderer, 15, 15, 25, 255)
    sdl.RenderClear(renderer)


    // 함선 렌더링 
    for &ship in ctx.ships {
	if ship.faction == .Player {
	    sdl.SetRenderDrawColor(renderer, 0, 255, 100, 255) // 민트색 (플레이어) 
	} else {
	    sdl.SetRenderDrawColor(renderer, 255, 50, 50, 255) // 붉은색 (적)
	}

	rect := sdl.Rect {
	    x = i32(ship.position.x) - 10,
	    y = i32(ship.position.y) - 10,
	    w = 20, 
	    h = 20,
	}
	sdl.RenderFillRect(renderer, &rect)
    }

    // UI 렌더링 
    im.Render()
    im_sdlrenderer2.RenderDrawData(im.GetDrawData(), renderer)
    sdl.RenderPresent(renderer)

    return running
}


main :: proc() {
    fmt.println("초기화 중...")

    // SDL 초기화 루틴 
    if sdl.Init(sdl.INIT_VIDEO) != 0 {
	fmt.eprintfln("SDL 초기화 실패 :%s", sdl.GetError())
	return
    }

    defer sdl.Quit() 


    // window, renderer 생성 
    window := sdl.CreateWindow(

	"Space RPG - Uncharted space ", 
	sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
	800, 600,
	sdl.WINDOW_SHOWN,
    )

    if window == nil {
	fmt.eprintfln("윈도우 생성 실패 %s", sdl.GetError())
	return
    }

    defer sdl.DestroyWindow(window)


    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC)
    if renderer == nil {

	fmt.eprintfln("렌더러 생성 실패 %s", sdl.GetError())

	return 
    }

    defer sdl.DestroyRenderer(renderer)

    // imgui context 설정 
    im.CHECKVERSION()
    im.CreateContext(nil)
    defer im.DestroyContext(nil)

    // 키보드 및 게임패드 활성화 
    io := im.GetIO()
    io.ConfigFlags += { .NavEnableKeyboard, .NavEnableGamepad }

    // 한국어 유니코드 범위 포인터 (U+AC00 ~ U+D7A3 등)
    korean_ranges := im.FontAtlas_GetGlyphRangesKorean(io.Fonts)

    // TTF 파일 경로 (Odin 문자열을 C 호환 문자열로 변환)
    font_path := cstring("assets/fonts/spoqa/SpoqaHanSansNeo-Medium.ttf")

    // 폰트 로드 (가독성을 위해 18.0 설정 )
    im.FontAtlas_AddFontFromFileTTF(io.Fonts, font_path, 18.0, nil, korean_ranges)

    // 기본 테마 
    im.StyleColorsDark(nil)

    // IMGUI 백엔드 연동 
    im_sdl2.InitForSDLRenderer(window, renderer)
    defer im_sdl2.Shutdown()

    im_sdlrenderer2.Init(renderer)
    defer im_sdlrenderer2.Shutdown()
    
    // SDL 초기화 루틴 종료 

    // == Game Context 설정  ==
    // 초기에는 MainMenu 로 설정 
    ctx := Game_Context {
	current_state = State_MainMenu {},
    }

    ctx.ships = make([dynamic]Ship)
    defer delete(ctx.ships)

    ctx.planets = make([dynamic]Planet)
    defer delete(ctx.planets)


    fmt.println("초기화 완료. 플레이어 함선 수", len(ctx.ships))

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
	running = main_loop(renderer, &ctx, dt)
    }

}
