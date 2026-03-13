package space_rpg

import sdl "vendor:sdl2"
import "core:c"
import "core:fmt"
import "core:strings"

// 아틀라스 초기화 
init_atlas :: proc(atlas: ^Atlas) {
    atlas.frames = make(map[string][]sdl.Rect)
}


// 사용이 끝났을때 데이터 삭제 
cleanup_atlas :: proc(atlas: ^Atlas) {

    for key, rects in atlas.frames {
	delete(rects)
	delete(key)
    }

    delete(atlas.frames)
}

// 특정 프레임의 Rect만 가져오기 
get_atlas_frame :: proc(atlas: ^Atlas, key: string, frame_index: int) -> (sdl.Rect, bool) {
    rects, exists := atlas.frames[key]

    if !exists || frame_index < 0 || frame_index >= len(rects) {
	return sdl.Rect{}, false
    }

    return rects[frame_index], true

}


// 텍스쳐를 가로/세로 폭으로 잘라 프레임 배열 생성 
generate_atlas_frames :: proc(atlas: ^Atlas, manager: ^Asset_Manager, texture_key: string, frame_w, frame_h: i32) -> bool {
    // 대상 텍스쳐 포인터를 가져온다.
    texture := get_texture(manager, texture_key)
    if texture == nil {
	return false
    }

    // GPU에서 크기를 조회 
    format: u32 
    access: c.int 
    tex_w, tex_h: c.int


    if sdl.QueryTexture(texture, &format, &access, &tex_w, &tex_h) != 0 {

	fmt.eprintfln("텍스쳐 조회 오류 [%s]", texture_key)
	return false
    }

    // 텍스쳐 크기를 통핸 열과 행갯수 
    cols := i32(tex_w) / frame_w 
    rows := i32(tex_h) / frame_h
    total_frames := cols * rows

    if total_frames <= 0 {
	fmt.eprintfln("아틀라스 계산 오류 [%s]: 프레임 크기(%d x %d) 가 원본보다 큼", texture_key, frame_w, frame_h)
	return false
    }


    // 계산된 총 프레임 수만큼 슬라이스 할당 
    rects := make([]sdl.Rect, total_frames, context.allocator)

    // 이중 루프를 돌며 프레임의 x, y, w, h 좌표를 잘라 넣음 
    idx := 0
    for y:i32 = 0; y < rows; y += 1 {
	for x: i32 = 0; x < cols; x += 1 {
	    rects[idx] = sdl.Rect {
		x = x * frame_w,
		y = y * frame_h,
		w = frame_w, 
		h = frame_h,
	    } 
	}

	idx += 1
    }

    // 키를 힙에 복사하고 해시맵 등록 
    cloned_key := strings.clone(texture_key, context.allocator)
    atlas.frames[cloned_key] = rects

    // 작업 완료 
    fmt.printf("아틀라스 [%s] 생성 완료. 총 %d 프레임 (%d x %d)\n", texture_key, total_frames, cols, rows)

    return true
}
