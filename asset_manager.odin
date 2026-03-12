package space_rpg

import sdl "vendor:sdl2"
import "core:os"
import "core:fmt"
import "core:strings"

Asset_Manager :: struct {
    textures: map[string]^sdl.Texture
}

init_asset_manager :: proc(manager: ^Asset_Manager, renderer: ^sdl.Renderer, config_path: string) -> bool {
    manager.textures = make(map[string]^sdl.Texture)

    // 설정 파일 읽기 
    data, ok := os.read_entire_file(config_path, context.allocator)

    if !ok {
	fmt.eprintfln("에셋 설정 파일을 읽을 수 없습니다: %s", config_path)
	return false
    }

    // 버퍼 메모리 폐기
    defer delete(data)

    // 파싱 (임시 할당자를 이용한 쓰레기 자동 청소)
    content := string(data)
    lines := strings.split_lines(content, context.temp_allocator)

    for line in lines {
	trimmed := strings.trim_space(line)
	if len(trimmed) == 0 || trimmed[0] == "#" do continue

	parts := strings.fields(trimmed, context.temp_allocator)
	if len(parts) != 2 do continue

	asset_name := parts[0]
	file_path := parts[1]

	// 텍스쳐 로드

	asset_texture, asset_ok := load_texture(renderer, file_path)
	
	if !asset_ok do continue

	cloned_key := strings.clone(asset_name, context.allocator)

	manager.textures[cloned_key] = asset_texture
    }

    return true
}


cleanup_asset_manager :: proc(manager: ^Asset_Manager) {
    for key, texture in manager.textures {

	sdl.DestroyTexture(texture)
	delete(key)
    }

    delete(manager.textures)

}
