package file_mapping_producer

import "core:mem"
import win32 "core:sys/windows"
import "core:fmt"
import "core:unicode/utf8"
import "core:slice"
import "core:strings"

MAPPING_NAME :: "OdinFileMapExample"
FILE_NAME :: "MappingTempFile"
INFORMATION_TEXT :: "Welcome to the Ginger Dome"
USE_FILE :: true

Awesome_Data :: struct {
	secrets : u64,
	information : [128]rune,
	gingers_spotted : i32
}

main :: proc() {
	context.allocator = context.temp_allocator

	mapping_size: u64 = size_of(Awesome_Data)
	size_low := u32(mapping_size & 0xFFFFFFFF)
	size_high := u32(mapping_size >> 32)

	fmt.println("The size of the data is", size_of(Awesome_Data))

	when USE_FILE {
		// The maximum possible return value is MAX_PATH+1 (261) (GetTempPathW)
		temp_buf : [win32.MAX_PATH + 1]u16
		num_bytes := win32.GetTempPathW(win32.MAX_PATH + 1, raw_data(temp_buf[:]))
		temp_dir, _ := win32.wstring_to_utf8(raw_data(temp_buf[:]), int(num_bytes))
		concat_path := strings.concatenate({temp_dir, FILE_NAME})
	
		file_handle := win32.CreateFileW(
			win32.utf8_to_wstring(concat_path), win32.FILE_ALL_ACCESS,
			(win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE),
			nil, win32.CREATE_ALWAYS, win32.FILE_ATTRIBUTE_NORMAL, nil
		)
		if file_handle == nil {
			fmt.println("Error creating temp file")
			return
		}

		mapping_handle := win32.CreateFileMappingW(
			file_handle, nil, win32.PAGE_READWRITE, 
			size_high, size_low, win32.utf8_to_wstring(MAPPING_NAME)
		)
		if mapping_handle == nil {
			fmt.println("Error in CreateFileMappingW") 
			return
		}
	} else {
		mapping_handle := win32.CreateFileMappingW(nil, nil, win32.PAGE_READWRITE, size_high,size_low, win32.utf8_to_wstring(MAPPING_NAME))
		if mapping_handle == nil {
			fmt.println("Error in CreateFileMappingW") 
			return
		}
	}

	mapping_buffer := win32.MapViewOfFile(mapping_handle, win32.FILE_MAP_ALL_ACCESS, 0, 0, uint(mapping_size))
	if mapping_buffer == nil {
		fmt.println("Error in MapViewOfFile") 
		return
	}
	
	// Not really the best way to send a string probably i should find a way to both send/recieve
	// an actual "string" type 
	info := utf8.string_to_runes(INFORMATION_TEXT)
	info_buf : [128]rune
	mem.copy(&info_buf, raw_data(info), len(info) * size_of(rune)) 

	sent_data := Awesome_Data {
		secrets = 100,
		information = info_buf,
		gingers_spotted = 1,
	}
	mem.copy(mapping_buffer, &sent_data, size_of(sent_data))

	for {
		
	}

	// This never really gets hit here but you should do this
	unmapped := win32.UnmapViewOfFile(mapping_buffer)
	if !unmapped {
		fmt.println("There was an error unmapping the view") 
	}

	// (This too)
	free_all(context.temp_allocator)
}
