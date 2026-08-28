extends StaticBody3D
class_name PrinterStatic

const SALE_PAPER_SCENE = preload("res://Interactive/Paper/sale_paper.tscn")

@onready var interactable: Interactable = $Interactable
@onready var output_paper: MeshInstance3D = $Paper

var printed_paper: SalePaper
var queued_sales: Array[Dictionary] = []

func _ready() -> void:
	for phone in get_tree().get_nodes_in_group("office_phone"):
		var queue_sale_callable := Callable(self, "queue_sale")
		if phone.has_signal("sale_queued") and !phone.is_connected("sale_queued", queue_sale_callable):
			phone.connect("sale_queued", queue_sale_callable)

func queue_sale(sale: Dictionary) -> void:
	if sale.is_empty():
		return

	queued_sales.append(sale.duplicate(true))

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	if queued_sales.is_empty() or _has_output_paper_waiting():
		print("printer idle")
		return

	_spawn_sale_paper(queued_sales.pop_front())
	print("report printed")

func _spawn_sale_paper(sale: Dictionary) -> void:
	if _has_output_paper_waiting():
		return

	printed_paper = SALE_PAPER_SCENE.instantiate() as SalePaper
	get_tree().current_scene.add_child(printed_paper)
	printed_paper.global_transform = _get_paper_spawn_transform()
	printed_paper.setup(sale)
	printed_paper.freeze = true

func _has_output_paper_waiting() -> bool:
	return printed_paper != null and is_instance_valid(printed_paper) and !printed_paper.is_held

func _get_paper_spawn_transform() -> Transform3D:
	var paper_transform := output_paper.global_transform
	return paper_transform
