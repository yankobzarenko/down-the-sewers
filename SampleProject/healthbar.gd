extends ProgressBar

func _ready() -> void:
	var player = PlayerManager.player
	if player:
		max_value = player.max_health
		value = player.health
		player.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max: int) -> void:
	max_value = max
	value = current
