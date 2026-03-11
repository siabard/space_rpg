package space_rpg

import "core:fmt"

import sdl "vendor:sdl2" 
import img "vendor:sdl2/image"

import "core:strings"

import im "odin-imgui"
import im_sdl2 "odin-imgui/imgui_impl_sdl2"
import im_sdlrenderer2 "odin-imgui/imgui_impl_sdlrenderer2"


// 폰트 텍스쳐를 로드하고 성공여부를 반환 
load_texture :: proc(renderer: ^sdl.Renderer, path: string) -> (texture: ^sdl.Texture, ok: bool) {

    // 1. Odin 문자열을 C문자열로 변환 
    // context.temp_allocator를 사용, 매 프레임 끝날 때마다 메모리가 자동 해제되도록 한다.

    c_path := strings.clone_to_cstring(path, context.temp_allocator)

    // 2. RAM에 픽셀 데이터 로드 (Surface)
    surface := img.Load(c_path)
    if surface == nil {
	fmt.eprintfln("이미지 로드 실패 (%s): %s", path, sdl.GetError())
	return nil, false
    }

    // 함수가 종료될 때 surface 삭제 
    defer sdl.FreeSurface(surface)

    // 3. VRAM으로 데이터 전송 (Texture)
    surface_text := sdl.CreateTextureFromSurface(renderer, surface)
    if surface_text == nil {
	fmt.eprintfln("텍스쳐 생성 실패 (%s): %s", path, sdl.GetError())
	return nil, false
    }

    return surface_text, true

    
}


// 폰트 전용 텍스쳐 초기화 함수 
load_font_textures :: proc(renderer: ^sdl.Renderer) -> (fonts: Font_Textures, ok: bool) {
    // 1. SDL_Image PNG 서브시스템 초기화 
    img_flags := img.INIT_PNG | img.INIT_JPG;
    if img.Init(img_flags) & img_flags != img_flags {
	fmt.eprintfln("SDL2_Image 초기화 실패: %s", sdl.GetError())
	return fonts, false
    }

    // ascii 폰트 로드 
    ascii_tex, ascii_ok := load_texture(renderer, "assets/fonts/ascii.png" )
    if !ascii_ok {
	return fonts, false
    }

    // hangul 포늩 로드 
    hangul_tex, hangul_ok := load_texture(renderer, "assets/fonts/hangul.png" )
    if !hangul_ok {
	return fonts, false
    }

    fonts.ascii = ascii_tex
    fonts.hangul = hangul_tex

    return fonts, true
}


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

    // 폰트파일 읽어들이기 (sdl2_image)
    fonts, fonts_ok := load_font_textures(ctx.renderer)
    ctx.fonts = fonts

    // 입력처리기 
    init_input_manager(&ctx.input)

    fmt.println("초기화 완료. 플레이어 함선 수", len(ctx.ships))
}


clean_up :: proc(ctx: ^Game_Context) {

    fmt.println("closing program...")

    // 텍스쳐 삭제 

    if ctx.fonts.hangul != nil {

	sdl.DestroyTexture(ctx.fonts.hangul)
    }
    if ctx.fonts.ascii != nil {
	sdl.DestroyTexture(ctx.fonts.ascii)
    }

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
