extends TileMapLayer
# Скрипт для процедурной генерации проходимой вверх платформер-карты.
# Поместите этот скрипт на ноду TileMapLayer с назначенным TileSet.

@export_range(1, 128)
var width: int = 24             # ширина в тайлах
@export_range(5, 128)
var height: int = 14            # высота в тайлах
@export var seed: int = 0       # 0 = случайный seed

# Параметры способности игрока (в тайлах)
@export_range(1, 8)
var jump_height: int = 3        # макс. подъём между соседними колонками
@export_range(0, 8)
var max_step_up: int = 1        # ограничение на подъём (можно использовать для плавности)
@export_range(0, 8)
var max_step_down: int = 2      # ограничение на спуск

# Тайлы (укажите в инспекторе)
@export var source_id: int = 1
@export var ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var decoration_atlas_coords: Vector2i = Vector2i(0, 0)

# Генерация параметров платформ (минимальная и максимальная длина горизонтального участка)
@export_range(1, 10)
var min_platform_len: int = 2
@export_range(1, 10)
var max_platform_len: int = 5

@export_range(0.0, 1.0, 0.01)
var extra_platform_chance: float = 0.12   # шанс добавить случайную платформу

func _ready() -> void:
	generate_level()
	update_internals()

func generate_level() -> void:
	# Инициализация генератора случайных чисел
	if seed != 0:
		seed(seed)
	else:
		randomize()
	
	clear_map()
	
	# 1. Генерируем массив высот (логический y) для каждой колонки x от 0 до width-1
	var path_heights := generate_path_heights()
	
	# 2. Размещаем основные платформы на основе сгруппированных участков
	place_platforms(path_heights)
	
	# 3. Добавляем стартовую зону (несколько тайлов внизу слева)
	for sx in range(0, 3):
		_set_ground_cell(sx, 0)
	
	# 4. Добавляем случайные декоративные платформы (не мешают основному пути)
	place_decorations(path_heights)

# Генерирует массив высот с гарантированным подъёмом до самого верха
func generate_path_heights() -> Array[int]:
	var heights: Array[int] = []
	heights.resize(width)
	
	# Начальная высота = 0 (низ), конечная = height-1 (верх)
	var start_y = 0
	var end_y = height - 1
	
	# Линейно возрастающий тренд
	for x in range(width):
		var t = float(x) / (width - 1)
		var base_y = start_y + t * (end_y - start_y)
		# Добавляем случайное отклонение, но ограничиваем его так,
		# чтобы перепады между соседними x не превышали jump_height
		var deviation = 0
		if x > 0:
			# Отклонение может быть как вверх, так и вниз, но не больше max_step_up/down
			deviation = randi_range(-max_step_down, max_step_up)
		
		var candidate = int(round(base_y + deviation))
		# Ограничиваем допустимые значения
		candidate = clamp(candidate, 0, height - 1)
		
		# Проверяем, чтобы разница с предыдущей высотой не превышала jump_height
		if x > 0:
			var prev = heights[x-1]
			if candidate - prev > jump_height:
				candidate = prev + jump_height
			elif prev - candidate > jump_height:
				candidate = prev - jump_height
		
		heights[x] = candidate
	
	# Убедимся, что последняя точка точно наверху (может потребоваться корректировка)
	heights[width-1] = end_y
	
	# Пройдёмся ещё раз справа налево, чтобы сгладить резкие скачки в конце
	for x in range(width-2, -1, -1):
		var next = heights[x+1]
		if next - heights[x] > jump_height:
			heights[x] = next - jump_height
		elif heights[x] - next > jump_height:
			heights[x] = next + jump_height
	
	return heights

# Размещает основные платформы: группирует подряд идущие одинаковые высоты
func place_platforms(heights: Array[int]) -> void:
	var x = 0
	while x < width:
		var current_y = heights[x]
		var start_x = x
		# Ищем конец участка с той же высотой
		while x < width and heights[x] == current_y:
			x += 1
		var end_x = x - 1
		
		# Длина платформы
		var platform_len = end_x - start_x + 1
		# Можно дополнительно варьировать длину, но пока берём как есть
		# Ставим тайлы на всём протяжении платформы
		for px in range(start_x, end_x + 1):
			_set_ground_cell(px, current_y)

# Добавляет случайные «парящие» платформы (декор)
func place_decorations(heights: Array[int]) -> void:
	for x in range(width):
		if randf() < extra_platform_chance:
			# Выбираем высоту выше основного пути
			var base = heights[x]
			var min_y = min(base + 1, height - 2)
			var max_y = height - 2
			if min_y > max_y:
				continue
			var py = randi_range(min_y, max_y)
			# Проверяем, что клетка свободна
			if not _cell_is_set(x, py):
				_set_deco_cell(x, py)
				# Иногда удлиняем влево/вправо
				if randf() < 0.4:
					if x + 1 < width and not _cell_is_set(x + 1, py):
						_set_deco_cell(x + 1, py)
					if x - 1 >= 0 and not _cell_is_set(x - 1, py):
						_set_deco_cell(x - 1, py)

# Очистка карты
func clear_map() -> void:
	for x in range(width):
		for y in range(height):
			set_cell(Vector2i(x, y), -1)

# Преобразование логического y (0 = низ) в координату тайловой карты (y растёт вниз)
func logical_to_tilemap_y(logical_y: int) -> int:
	return (height - 1) - logical_y

# Установка основного тайла
func _set_ground_cell(x: int, logical_y: int) -> void:
	if logical_y < 0 or logical_y >= height or x < 0 or x >= width:
		return
	var tilemap_y = logical_to_tilemap_y(logical_y)
	set_cell(Vector2i(x, tilemap_y), source_id, ground_atlas_coords)

# Установка декоративного тайла
func _set_deco_cell(x: int, logical_y: int) -> void:
	if logical_y < 0 or logical_y >= height or x < 0 or x >= width:
		return
	var tilemap_y = logical_to_tilemap_y(logical_y)
	set_cell(Vector2i(x, tilemap_y), source_id, decoration_atlas_coords)

# Проверка, занята ли клетка
func _cell_is_set(x: int, logical_y: int) -> bool:
	var tilemap_y = logical_to_tilemap_y(logical_y)
	return get_cell_source_id(Vector2i(x, tilemap_y)) != -1
