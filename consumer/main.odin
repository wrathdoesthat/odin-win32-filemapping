package file_mapping_consumer

import "core:mem"
import win32 "core:sys/windows"
import "core:fmt"
import "core:unicode/utf8"

MAPPING_NAME :: "OdinFileMapExample"

Awesome_Data :: struct {
	secrets :         u64,
	information :     [128]rune,
	gingers_spotted : i32
}

main :: proc() {
	context.allocator = context.temp_allocator

	mapping_handle := win32.OpenFileMappingW(win32.FILE_MAP_ALL_ACCESS, false, win32.utf8_to_wstring(MAPPING_NAME))
	if mapping_handle == nil {
		fmt.println("Error in OpenFileMappingW is the producer running?") 
		return
	}

	mapping_buffer := win32.MapViewOfFile(mapping_handle, win32.FILE_MAP_ALL_ACCESS, 0,0, size_of(Awesome_Data))
	if mapping_buffer == nil {
		fmt.println("Error in MapViewOfFile") 
		return
	}

	recieved_data : [size_of(Awesome_Data)]u8
	mem.copy(&recieved_data, mapping_buffer, size_of(Awesome_Data))
	data := transmute(Awesome_Data)recieved_data

	data_str := utf8.runes_to_string(data.information[:])

	fmt.println(data.secrets, data.gingers_spotted, data.information, data_str)
	free_all(context.temp_allocator)
}
