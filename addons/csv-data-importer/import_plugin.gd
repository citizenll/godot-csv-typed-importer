@tool
extends EditorImportPlugin

enum Presets { CSV }
enum Delimiters { COMMA, TAB, SEMICOLON }

const ALLOW_TYPES = ["str", "int", "float", "bool", "json"]

func _get_importer_name():
	return "citizenl.godot-csv-importer"


func _get_visible_name():
	return "CSV Data"


func _get_priority():
	# The built-in Translation importer needs a restart to switch to other importer
	return 2.0

func _get_import_order():
	return 0

func _get_recognized_extensions():
	return ["csv", "tsv"]


func _get_save_extension():
	return "tres"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Presets.size()


func _get_preset_name(preset):
	match preset:
		Presets.CSV:
			return "CSV"
		_:
			return "Unknown"


func _get_import_options(_path, preset):
	var delimiter = Delimiters.COMMA
	var headers = true
	return [
		{name="delimiter", default_value=delimiter, property_hint=PROPERTY_HINT_ENUM, hint_string="Comma,Tab, Semicolon"},
		{name="describe_headers", default_value=headers},
	]


func _get_option_visibility(_path, option, options):
	return true	# Godot does not update the visibility immediately
	if option == "force_float":
		return options.detect_numbers
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var delim: String
	match options.delimiter:
		Delimiters.COMMA:
			delim = ","
		Delimiters.TAB:
			delim = "\t"
		Delimiters.SEMICOLON:
			delim = ";"

	var file = FileAccess.open(source_file, FileAccess.READ)
	
	if not file:
		printerr("Failed to open file: ", source_file)
		return FAILED

	var lines := Array2D.new()

	var meta = _parse_headers(file, options,delim)
	while not file.eof_reached():
		var line = file.get_csv_line(delim)
		
		var row = _parse_typed(line, meta.headers, meta.field_types)
		if row==null or not row.size():
			push_warning("[csv-importer]:csv row data null ",line)
			continue
		lines.append_row(row)
		
	file.close()
	
	# do not setup here
	var data = preload("csv_data.gd").new(false)
	var rows = lines.get_data() 
	data.records = rows
	data.headers = meta.headers

	var filename = save_path + "." + _get_save_extension()
	var err = ResourceSaver.save(data, filename, ResourceSaver.FLAG_NONE)
	if err != OK:
		printerr("Failed to save resource: ", err)
	return err


func _parse_headers(f: FileAccess, options,delim):
	var model_name = ""
	if options.describe_headers:
		var _desc = f.get_csv_line(delim)
		model_name= _desc[0]
	var headers = f.get_csv_line(delim)
	var types = f.get_csv_line(delim)
	#
	var field_indexs = {}
	var field_types = {}
	if headers[0] != "id":
		push_error("First column must be 'id'")
		return []
	for i in range(headers.size()):
		field_indexs[headers[i]] = i

	for i in range(types.size()):
		field_types[headers[i]] = types[i]
	
	return {"model_name": model_name, "headers": headers,"types": types, "field_indexs": field_indexs, "field_types": field_types}


func _parse_typed(csv_row: PackedStringArray, headers:PackedStringArray, types):
	var column = headers.size()
	if csv_row.size() != column:
		push_warning("[csv-importer]:csv row data not enough ",column," - > ",csv_row.size()," = ",csv_row)
		return []
	var row = []
	for i in range(headers.size()):
		var key = headers[i]
		var field_type = types[key]
		assert(field_type in ALLOW_TYPES)
		row.append(_parse_typed_value(csv_row[i], field_type))
	return row


func _parse_typed_value(p_value: String, p_type: String):
	match p_type:
		"str":
			return p_value
		"int":
			if p_value.is_empty():
				p_value = "0"
			return int(p_value)
		"float":
			if p_value.is_empty():
				p_value = "0"
			return float(p_value)
		"bool":
			if p_value.is_empty():
				p_value = "false"  #default is false
			return str_to_var(p_value)
		"json":
			if p_value.is_empty():
				p_value = "[]"
			p_value = p_value.replace("`", "\"")
			return str_to_var(p_value)
		_:
			push_error("can not parse type ", p_type)
			return p_value
