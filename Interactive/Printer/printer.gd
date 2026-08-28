extends StaticBody3D
class_name PrinterStatic

const SALE_PAPER_SCENE = preload("res://Interactive/Paper/sale_paper.tscn")

@onready var interactable: Interactable = $Interactable
@onready var output_paper: MeshInstance3D = $Paper

var printed_paper: SalePaper

func _ready() -> void:
	pass

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	if SaleStatus.currSaleState != SaleStatus.SaleState.PRINT_REPORT:
		print("printer idle")
		return

	_spawn_sale_paper()
	SaleStatus.mark_report_printed()
	print("report printed")

func _spawn_sale_paper() -> void:
	if printed_paper != null and is_instance_valid(printed_paper):
		return

	printed_paper = SALE_PAPER_SCENE.instantiate() as SalePaper
	get_tree().current_scene.add_child(printed_paper)
	printed_paper.global_transform = _get_paper_spawn_transform()
	printed_paper.setup(SaleStatus.current_sale.get("company", "Unknown Company"))
	printed_paper.freeze = true

func _get_paper_spawn_transform() -> Transform3D:
	var paper_transform := output_paper.global_transform
	return paper_transform
