package space_rpg

import sdl "vendor:sdl2"
import "core:mem"

// SDL 스캔코드의 최대 갯수와 마우스 최대 갯수 
NUM_KEYS :: i32(sdl.NUM_SCANCODES)
NUM_MOUSE_BUTTONS :: 5

Input_Manager :: struct {
    // 키보드 상태 
    keys_held:     [NUM_KEYS]bool,
    keys_pressed:  [NUM_KEYS]bool,
    keys_released: [NUM_KEYS]bool,

    // 마우스 상태 
    mouse_held:     [NUM_MOUSE_BUTTONS]bool,
    mouse_pressed:  [NUM_MOUSE_BUTTONS]bool,
    mouse_released: [NUM_MOUSE_BUTTONS]bool,
}


// 매 프레임 인픗 handler 초기화 
reset_input_per_frame :: proc(input: ^Input_Manager) {
    mem.zero_item(&input.keys_pressed)
    mem.zero_item(&input.keys_released)

    mem.zero_item(&input.mouse_pressed)
    mem.zero_item(&input.mouse_released)

}


init_input_manager :: proc(input: ^Input_Manager) {

    mem.zero_item(input)
}
