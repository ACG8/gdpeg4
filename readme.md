# "GDPeg" Parsing Expression Grammar for GDScript

## How to Use

### Class

```
func numbers( s:String ):
	return { "number": int(s) }

func binop( root, group:Array ):
	printt( root, group )
	if len( group ) < 2:
		return root

	return { "op": group[0], "left": root, "right": group[1] }

func _ready( ):
	var numbers:Peg.PegTree = Peg.capture( Peg.regex( "[0-9]+" ), funcref( self, "numbers" ) )
	var factor:Peg.PegTree = Peg.capture_folding(
		Peg.concat([
			numbers,
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
						numbers,
					])
				),
				0
			)
		]),
		funcref( self, "binop" )
	)
	var term:Peg.PegTree = Peg.capture_folding(
		Peg.concat([
			factor,
			Peg.greedy(
				Peg.capture_group(
					Peg.concat([
						Peg.capture(
							Peg.select([
								Peg.literal( "+" ),
								Peg.literal( "-" ),
							])
						),
						factor,
					])
				),
				0
			)
		]),
		funcref( self, "binop" )
	)
	var parser:Peg.PegTree = term
	var result:Peg.PegResult = term.check( "1+2+3*4+5", 0 )

	print( result.accept )
	print( result.capture )
```

### Original PEG

TODO. まだ未実装

## License

MIT License

## Author

あるる / きのもと 結衣 @arlez80
