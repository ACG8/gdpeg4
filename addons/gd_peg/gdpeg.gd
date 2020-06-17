"""
	Parsing Expression Grammar for Godot Engine
		by あるる / きのもと 結衣 @arlez80
"""

class PegResult:
	var accept:bool
	var length:int
	var capture
	var capture_group:Array

	func _init( _accept:bool = false, _length:int = 0, _capture = null, _capture_group:Array = [] ):
		self.accept = _accept
		self.length = _length
		self.capture = _capture
		self.capture_group = _capture_group

class PegTree:
	func parse( buffer:String, p:int ) -> PegResult:
		return PegResult.new( false )

class PegCapture extends PegTree:
	var a:PegTree
	var f:FuncRef

	func _init( _a:PegTree, _f:FuncRef = null ):
		self.a = _a
		self.f = _f

	func parse( buffer:String, p:int ) -> PegResult:
		var ra:PegResult = a.parse( buffer, p )
		if ra.accept:
			var s:String = buffer.substr( p, ra.length )
			if self.f != null:
				ra.capture = f.call_func( s )
			else:
				ra.capture = s
			return ra

		return PegResult.new( false )

class PegCaptureFolding extends PegTree:
	var a:PegTree
	var f:FuncRef

	func _init( _a:PegTree, _f:FuncRef ):
		self.a = _a
		self.f = _f

	func parse( buffer:String, p:int ) -> PegResult:
		var ra:PegResult = a.parse( buffer, p )
		if ra.accept:
			for t in ra.capture_group:
				ra.capture = f.call_func( ra.capture, t )
			ra.capture_group = []
			return ra

		return PegResult.new( false )

class PegCaptureGroup extends PegTree:
	var a:PegTree

	func _init( _a:PegTree ):
		self.a = _a

	func parse( buffer:String, p:int ) -> PegResult:
		var ra:PegResult = a.parse( buffer, p )
		if ra.accept:
			ra.capture_group = ra.capture
			ra.capture = null
			return ra

		return PegResult.new( false )

class PegLiteral extends PegTree:
	var literal:String = ""
	var literal_length:int = 0

	func _init( s:String ):
		self.literal = s
		self.literal_length = len( s )

	func parse( buffer:String, p:int ) -> PegResult:
		if buffer.substr( p, self.literal_length ) == self.literal:
			return PegResult.new( true, self.literal_length )
		else:
			return PegResult.new( false )

class PegRegex extends PegTree:
	var regex:RegEx

	func _init( pattern:String ):
		self.regex = RegEx.new( )
		self.regex.compile( pattern )

	func parse( buffer:String, p:int ) -> PegResult:
		var result:RegExMatch = self.regex.search( buffer, p )

		if result == null:
			return PegResult.new( false )

		if result.get_start( ) == p:
			return PegResult.new( true, len( result.strings[0] ) )
		else:
			return PegResult.new( false )

class PegConcat extends PegTree:
	var a:Array

	func _init( _a:Array ):
		self.a = _a

	func parse( buffer:String, p:int ) -> PegResult:
		var total_length:int = 0
		var total_capture = []
		var total_capture_group:Array = []

		for t in self.a:
			var ra:PegResult = t.parse( buffer, p )
			if not ra.accept:
				return PegResult.new( false )
			p += ra.length
			total_length += ra.length
			match typeof( ra.capture ):
				TYPE_NIL:
					pass
				TYPE_ARRAY:
					if 0 < len( ra.capture ):
						total_capture.append( ra.capture )
				_:
					total_capture.append( ra.capture )

			if 0 < len( ra.capture_group ):
				total_capture_group.append( ra.capture_group )

		# 二重になっている場合
		if len( total_capture ) == 1:
			total_capture = total_capture[0]
		if len( total_capture_group ) == 1:
			total_capture_group = total_capture_group[0]

		return PegResult.new( true, total_length, total_capture, total_capture_group )

class PegSelect extends PegTree:
	var a:Array

	func _init( _a:Array ):
		self.a = _a

	func parse( buffer:String, p:int ) -> PegResult:
		for t in self.a:
			var ra:PegResult = t.parse( buffer, p )
			if ra.accept:
				return ra

		return PegResult.new( false )

class PegGreedy extends PegTree:
	var a:PegTree
	var least:int
	var length:int

	func _init( _a:PegTree, _least:int = 0, _length:int = -1 ):
		self.a = _a
		self.least = _least
		self.length = _length

	func parse( buffer:String, p:int ) -> PegResult:
		var total_length:int = 0
		var total_capture = []
		var total_capture_group:Array = []
		var count:int = 0

		while true:
			var ra:PegResult = a.parse( buffer, p )
			if not ra.accept:
				break
			total_length += ra.length
			match typeof( ra.capture ):
				TYPE_NIL:
					pass
				TYPE_ARRAY:
					if 0 < len( ra.capture ):
						total_capture.append( ra.capture )
				_:
					total_capture.append( ra.capture )
			if 0 < len( ra.capture_group ):
				total_capture_group.append( ra.capture_group )

			p += ra.length
			count += 1
			if self.length != -1 and self.length <= count:
				break

		# 二重になっている場合
		if len( total_capture ) == 1:
			total_capture = total_capture[0]

		return PegResult.new( ( self.least <= count ) and ( self.length == -1 or self.length <= count ), total_length, total_capture, total_capture_group )

class PegAheadAccept extends PegTree:
	var a:PegTree

	func _init( _a:PegTree ):
		self.a = _a

	func parse( buffer:String, p:int ) -> PegResult:
		var ra:PegResult = a.parse( buffer, p )
		return PegResult.new( ra.accept, 0 )

class PegAheadNot extends PegTree:
	var a:PegTree

	func _init( _a:PegTree ):
		self.a = _a

	func parse( buffer:String, p:int ) -> PegResult:
		var ra:PegResult = a.parse( buffer, p )
		return PegResult.new( not ra.accept, 0 )

static func capture( _a:PegTree, _f:FuncRef = null ) -> PegTree:
	return PegCapture.new( _a, _f )

static func capture_folding( _a:PegTree, _f:FuncRef = null ) -> PegTree:
	return PegCaptureFolding.new( _a, _f )

static func capture_group( _a:PegTree ) -> PegTree:
	return PegCaptureGroup.new( _a )

static func literal( s:String ) -> PegTree:
	return PegLiteral.new( s )

static func regex( pattern:String ) -> PegTree:
	return PegRegex.new( pattern )

static func concat( _a:Array ) -> PegTree:
	return PegConcat.new( _a )

static func select( _a:Array ) -> PegTree:
	return PegSelect.new( _a )

static func greedy( _a:PegTree, _least:int = 0, _length:int = -1 ) -> PegTree:
	return PegGreedy.new( _a, _least, _length )

static func ahead_accept( _a:PegTree ) -> PegTree:
	return PegAheadAccept.new( _a )

static func ahead_not( _a:PegTree ) -> PegTree:
	return PegAheadNot.new( _a )
