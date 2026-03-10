package space_rpg

import "core:fmt"
import sdl "vendor:sdl2" 

import im "odin-imgui"
import im_sdl2 "odin-imgui/imgui_impl_sdl2"
import im_sdlrenderer2 "odin-imgui/imgui_impl_sdlrenderer2"


init :: proc(ctx: ^Game_Context) {
    fmt.println("초기화 중...")

    // SDL 초기화 루틴 
    if sdl.Init(sdl.INIT_VIDEO) != 0 {
	fmt.eprintfln("SDL 초기화 실패 :%s", sdl.GetError())
	return
    }

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
    ctx.window = window

    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC)
    if renderer == nil {
	fmt.eprintfln("렌더러 생성 실패 %s", sdl.GetError())
	return 
    }

    ctx.renderer = renderer

    // imgui context 설정 
    im.CHECKVERSION()
    im.CreateContext(nil)


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

    im_sdlrenderer2.Init(renderer)
    
    // == Game Context 설정  ==
    // 초기에는 MainMenu 로 설정 
    ctx.current_state = State_MainMenu {}

    ctx.ships = make([dynamic]Ship)

    ctx.planets = make([dynamic]Planet)

    fmt.println("초기화 완료. 플레이어 함선 수", len(ctx.ships))
}


clean_up :: proc(ctx: ^Game_Context) {

    fmt.println("closing program...")

    // 데이터 삭제 
    delete(ctx.ships)
    delete(ctx.planets)

    // imgui 정리 
    im_sdlrenderer2.Shutdown()
    im_sdl2.Shutdown()
    im.DestroyContext(nil)

    // SDL clean up
    if ctx.renderer != nil {
	sdl.DestroyRenderer(ctx.renderer)
    }
 
    if ctx.window != nil {
	sdl.DestroyWindow(ctx.window)
    } 

    sdl.Quit()
}
