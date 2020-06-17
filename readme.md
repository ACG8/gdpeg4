# "GDPeg" Parsing Expression Grammar for GDScript

## How to Use

### Class

```
const Peg: = preload( "res://addons/gd_peg/gdpeg.gd")

func numbers( s:String ):
	return { "number": int(s) }

func binop( root, group:Array ):
	printt( root, group )
	if len( group ) < 2:
		return root

	return { "op": group[0], "left": root, "right": group[1] }

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
	print( result.capture )
```

### Original PEG

TODO. まだ未実装。以下のように、よくあるPEGを書いたら使えるようになるようにする予定。

```
var parser: = Peg.generate("""
expr < term ( [+\-] term )*
term < factor ( [*/] factor )*
factor < number / "(" expr ")"
number < [0-9]+
""")
```

## License

MIT License

## Author

あるる / きのもと 結衣 @arlez80
