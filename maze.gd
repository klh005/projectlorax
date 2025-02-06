extends Node3D

@export var width: int = 100  # Width of the maze
@export var height: int = 100  # Height of the maze
@export var maze_height: int = 5
@export var gridmap: GridMap  # Reference to the GridMap node

var maze: Array = []
var visited: Array = []

func _ready():
	generate_maze()
	build_maze()

func generate_maze():
	# Initialize the maze and visited arrays
	maze.resize(height)
	visited.resize(height)
	for y in range(height):
		maze[y] = []
		visited[y] = []
		for x in range(width):
			maze[y].append(1)  # 1 represents a wall
			visited[y].append(false)  # Not visited

	# Start the maze generation from a random cell
	var start_x = randi() % width
	var start_y = randi() % height
	visited[start_y][start_x] = true
	maze[start_y][start_x] = 0  # 0 represents a path

	var stack: Array = []
	stack.append(Vector2(start_x, start_y))

	while stack.size() > 0:
		var current = stack.pop_back()
		var x = current.x
		var y = current.y

		# Get neighbors
		var neighbors: Array = []
		for dir in [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]:
			var nx = x + dir.x * 2
			var ny = y + dir.y * 2
			if nx >= 0 and nx < width and ny >= 0 and ny < height and not visited[ny][nx]:
				neighbors.append(Vector2(nx, ny))

		if neighbors.size() > 0:
			stack.append(current)
			var next = neighbors[randi() % neighbors.size()]
			var nx = next.x
			var ny = next.y

			# Remove wall between current and next
			maze[y + (ny - y) / 2][x + (nx - x) / 2] = 0
			visited[ny][nx] = true
			maze[ny][nx] = 0
			stack.append(next)

func build_maze():
	for y in range(height):
		for x in range(width):
			var cell_position = Vector3i(x, 0, y)
			if maze[y][x] == 1:
				gridmap.set_cell_item(cell_position, 0)  # Wall tile
				for z in range(maze_height):
					gridmap.set_cell_item(Vector3i(cell_position.x, z, cell_position.z), 0)
			else:
				gridmap.set_cell_item(cell_position, -1)  # Empty space
