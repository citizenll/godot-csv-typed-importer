extends Resource

@export var headers := []  #column name
@export var records := []  #origin data

var _data:= {}  #column name to index

func setup():
	var field_indexs = {}
	for i in range(headers.size()):
		field_indexs[headers[i]] = i

	for i in range(headers.size()):
		for row in records:
			var primary_key = row[0]
			var row_data = {}
			for key in headers:
				var index = field_indexs[key]
				var value = row[index]
				row_data[key] = value
			_data[str(primary_key)]= row_data
	headers.clear()
	records.clear()
	
	return self


func fetch(primary_key):
	return _data.get(str(primary_key))
