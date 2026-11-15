extends Node2D
## The Short's scene root: `uses` is the uses of the one Item the pickups share, so a take can set it (the hook starts with one use left).

var uses: int:
	get:
		return $PickupA.item.uses
	set(value):
		$PickupA.item.uses = value
