package space_rpg

import "core:fmt"
import "core:testing"

Jaso :: struct {
    cho:  i32,
    mid:  i32,
    jong: i32,
}

Bul :: struct {
    cho:  i32,
    mid:  i32,
    jong: i32,
}

Language :: enum {
    Ascii,
    Hangul,
    HangulJamo,
    Kana,
    Arrow,
    NotImplemented,
}

NUM_OF_JONG :: 28 // 종성 총 갯수 (초성도 동일. 종성부용초성 규칙을 기억)
NUM_OF_MID  :: 21 // 중성 총 갯수 

// 언어판별 (범위매칭 Range matching 이용)
get_language :: proc(code: rune) -> Language {
    switch code {
	case 0x0000..=0x007f: return .Ascii
	case 0xAC00..=0xD7A3: return .Hangul
	case 0x3131..=0x3163: return .HangulJamo
	case 0x3040..=0x30ff: return .Kana
	case 0x2190..=0x2199: return .Arrow
	case:                 return .NotImplemented
    }
}

// 한글 유니코드를 자소 인덱스로 분리 
build_jaso :: proc(code: rune) -> Jaso {
    if get_language(code) == .Hangul {
	// rune을 연산할 때 i32로 캐스팅 
	hancode := i32(code) - 0xAc00
	jong := hancode % NUM_OF_JONG
	mid  := ((hancode - jong) / NUM_OF_JONG ) % NUM_OF_MID + 1
	cho  := ((hancode - jong) / NUM_OF_JONG) / NUM_OF_MID + 1
	return Jaso {cho, mid, jong}
    }

    return Jaso {0, 0, 0}
}

// 자소를 바탕으로 벌(set) 지정 
build_bul :: proc(jaso: Jaso) -> Bul {
    cho, mid, jong : i32 = 0, 0, 0

    if jaso.jong == 0 {
	// -- 받침이 업슨 경우 
	// 초성 벌수 결정 
	switch jaso.mid {
	case 1..=8, 21:       cho = 1 // ㅏㅐㅑㅒㅓㅔㅕㅖㅣ
	case 9, 13, 19:       cho = 2 // ㅗㅛㅡ
	case 14,18:           cho = 3 // ㅜㅠ
	case 10..=12, 20:     cho = 4 // ㅘㅙㅚㅢ
	case 15..=17:         cho = 5 // ㅝㅞㅟ
	}

	// 중성 벌수 결정 
	switch jaso.cho {
	case 1, 2:   mid = 1 // ㄱㄲ
	case 3..=19: mid = 2 // ㄱㄲ제외
	}
    } else {

	// -- 받침이 있는 경우
	// 초성 벌수 결정 
	switch jaso.mid {
	case 1..=8, 21:            cho = 6 //ㅏㅐㅑㅒㅓㅔㅕㅖㅣ
	case 9, 13, 14, 18, 19:    cho = 7 // ㅗㅛㅡㅜㅠ
	case 10..=12, 15..=17, 20: cho = 8 // ㅘㅙㅢㅚㅝㅞㅟ
	}

	// 중성 벌수 결정 
	switch jaso.cho {
	case 1, 2:   mid = 3 // ㄱㄲ
	case 3..=19: mid = 4 // ㄱㄲ제외
	}

	// 종성 벌수 결정 
	switch jaso.mid {
	case 1, 3, 10:                 jong = 1 // ㅏㅑㅘ
	case 5, 7, 12, 15, 17, 20, 21: jong = 2 // ㅓㅕㅚㅝㅟㅢㅣ
	case 2, 4, 6, 8, 11, 16:       jong = 3 // ㅐㅒㅔㅖㅙㅞ
	case 9, 13, 14,18, 19:         jong = 4 // ㅗㅛㅜㅠㅡ
	}
    }
    return Bul {cho, mid, jong}
}


@(test)
test_hangul_decomposition :: proc(t: ^testing.T) {
    statement := "의문"

    // utf8_to_ucs2가 필요 없습니다. string 순회가 곧 유니코드 디코딩입니다.
    for r in statement {
        jaso := build_jaso(r)
        bul := build_bul(jaso)
        
        // 한글인 경우에만 결과 출력 (디버깅용)
        if get_language(r) == .Hangul {
            fmt.printf("글자: %r, 유니코드: %X | 자소(초,중,종): %d, %d, %d | 벌(초,중,종): %d, %d, %d\n", 
                       r, i32(r), jaso.cho, jaso.mid, jaso.jong, bul.cho, bul.mid, bul.jong)
        } else {
            fmt.printf("글자: %r, 유니코드: %X (비한글)\n", r, i32(r))
        }
    }
}
