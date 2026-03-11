package space_rpg

import sdl "vendor:sdl2"
import "core:math/linalg"

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
State_Sailing :: struct { is_menu_open: bool }
State_Docked :: struct { docked_planet_id: u32}
State_Combat :: struct { target_ship_id: u32, turn_timer: u32}

// 4. 전역 게임 컨텍스트 
// 모든 게임 상태를 한 곳에 모은다. 
Game_Context :: struct {
    ships: [dynamic]Ship, // 모든 우주선 (동적 배열)
    planets: [dynamic]Planet, // 모든 행성 
    current_state: UI_State, // 현재 게임 상태 (항해, 정박, 전투)
    next_entity_id: u32,
    window: ^sdl.Window, // 윈도우
    renderer: ^sdl.Renderer, // 렌더러를 포함
    input: Input_Manager,
    dialog: Dialog_System,
    fonts: Font_Textures,
}
