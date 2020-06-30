# "GDPeg" Parsing Expression Grammar for GDScript

## How to Use

### Original PEG

```
const Peg: = preload( "res://addons/gdpeg/gdpeg.gd")

func number( s:String ):
	return { "number": int(s) }

func binop_non_folding( group:Array ):
	var node = group[0]
	for i in range( 1, len( group ), 2 ):
		node = { "op": group[i+0], "left": node, "right": group[i+1] }
	return node

func show_tree( leaf:Dictionary ) -> String:
	if leaf.has("op"):
		return "(%s %s %s)" % [
			leaf.op,
			show_tree( leaf.left ),
			show_tree( leaf.right )
		]
	else:
		return leaf.number

func _ready( ):
	var parser:Peg.PegTree = Peg.generate( """
		expr < term ( ~\"[+\\-]\" term )*
		term < factor ( ~\"[*/]\" factor )*
		factor < number / \"(\" expr \")\"
		number <~ ~\"[0-9]+\"
	""", {
		"expr": funcref( self, "binop_non_folding" )
	,	"term": funcref( self, "binop_non_folding" )
	,	"number": funcref( self, "number" )
	} )
	var result:Peg.PegResult = parser.parse( "1+2+3*4+5", 0 )

	print( result.accept )
	print( result.capture[0] )

	print( show_tree( result.capture[0] ) )
```

### Class

結構柔軟に書ける。

```
const Peg: = preload( "res://addons/gdpeg/gdpeg.gd")

func number( s:String ):
	return { "number": int(s) }

func binop( root:Array, group:Array ):
	return { "op": group[0], "left": root[0], "right": group[1] }

func show_tree( leaf:Dictionary ) -> String:
	if leaf.has("op"):
		return "(%s %s %s)" % [
			leaf.op,
			show_tree( leaf.left ),
			show_tree( leaf.right )
		]
	else:
		return leaf.number

func _ready( ):
	var number:Peg.PegTree = Peg.capture( Peg.regex( "[0-9]+" ), funcref( self, "number" ) )
	var term:Peg.PegTree = Peg.capture_folding(
		Peg.concat([
			number,
			Peg.greedy(
				Peg.capture_group(
					Peg.concat([
						Peg.capture(
							Peg.select([
								Peg.literal( "*" ),
								Peg.literal( "/" ),
								Peg.literal( "%" ),
							])
						),
						number,
					])
				),
				0
			)
		]),
		funcref( self, "binop" )
	)
	var expr:Peg.PegTree = Peg.capture_folding(
		Peg.concat([
			term,
			Peg.greedy(
				Peg.capture_group(
					Peg.concat([
						Peg.capture(
							Peg.select([
								Peg.literal( "+" ),
								Peg.literal( "-" ),
							])
						),
						term,
					])
				),
				0
			)
		]),
		funcref( self, "binop" )
	)
	var parser:Peg.PegTree = expr
	var result:Peg.PegResult = parser.parse( "1+2+3*4+5", 0 )

	print( result.accept )
	print( result.capture[0] )

	print( show_tree( result.capture[0] ) )
```

## TODO

* 高速化

## License

MIT License

## Author

あるる / きのもと 結衣 @arlez80
