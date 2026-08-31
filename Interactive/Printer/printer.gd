extends StaticBody3D
class_name PrinterStatic

const SALE_PAPER_SCENE = preload("res://Interactive/Paper/sale_paper.tscn")

const SCREEN_READY_COLOR := Color(0.0, 1.0, 0.12, 1.0)
const SCREEN_NO_QUEUE_COLOR := Color(0.347, 0.386, 0.363, 1.0)
const SCREEN_HACKED_COLOR := Color(0.45, 0.03, 0.02, 1.0)

const READY_SCREEN_EMISSION := 1.8
const NO_QUEUE_SCREEN_EMISSION := 0.35
const READY_LIGHT_ENERGY := 1.2

@onready var interactable: Interactable = $Interactable
@onready var output_paper: MeshInstance3D = $printer_big/Paper

@onready var printer_screen_mesh: MeshInstance3D = $printer_big/PrinterScreenMesh
@onready var paper_on_queue_light: OmniLight3D = $PaperOnQueueLight

var printed_paper: SalePaper
var queued_sales: Array[Dictionary] = []
var ready_screen_material: StandardMaterial3D
var no_queue_screen_material: StandardMaterial3D

func _ready() -> void:
	_setup_indicator_materials()
	_indicate_no_queue()
	for phone in get_tree().get_nodes_in_group("office_phone"):
		var queue_sale_callable := Callable(self, "queue_sale")
		if phone.has_signal("sale_queued") and !phone.is_connected("sale_queued", queue_sale_callable):
			phone.connect("sale_queued", queue_sale_callable)

func queue_sale(sale: Dictionary) -> void:
	if sale.is_empty():
		return

	queued_sales.append(sale.duplicate(true))
	_indicate_job_ready()

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	if queued_sales.is_empty():
		print("printer idle")
		_indicate_no_queue()
		return

	if _has_output_paper_waiting():
		print("printer output full")
		_indicate_job_ready()
		return

	_spawn_sale_paper(queued_sales.pop_front())
	print("report printed")
	if queued_sales.is_empty():
		_indicate_no_queue()
	else:
		_indicate_job_ready()

func _spawn_sale_paper(sale: Dictionary) -> void:
	if _has_output_paper_waiting():
		return

	printed_paper = SALE_PAPER_SCENE.instantiate() as SalePaper
	get_tree().current_scene.add_child(printed_paper)
	printed_paper.global_transform = _get_paper_spawn_transform()
	printed_paper.setup(sale)
	printed_paper.launch()

func _has_output_paper_waiting() -> bool:
	return printed_paper != null and is_instance_valid(printed_paper) and !printed_paper.is_held

func _get_paper_spawn_transform() -> Transform3D:
	var paper_transform := output_paper.global_transform
	return paper_transform

func _setup_indicator_materials() -> void:
	ready_screen_material = _create_screen_material(SCREEN_READY_COLOR, READY_SCREEN_EMISSION)
	no_queue_screen_material = _create_screen_material(SCREEN_NO_QUEUE_COLOR, NO_QUEUE_SCREEN_EMISSION)
	paper_on_queue_light.light_color = SCREEN_READY_COLOR
	paper_on_queue_light.light_energy = READY_LIGHT_ENERGY

func _indicate_job_ready() -> void:
	printer_screen_mesh.set_surface_override_material(0, ready_screen_material)
	paper_on_queue_light.visible = true

func _indicate_no_queue() -> void:
	printer_screen_mesh.set_surface_override_material(0, no_queue_screen_material)
	paper_on_queue_light.visible = false

func _create_screen_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material
