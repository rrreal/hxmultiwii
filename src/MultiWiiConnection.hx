
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import MultiWiiProtocol;

enum MultiWiiConnectionState {
	header(i:Int);
	size;
	code;
	data;
	checksum;
}

@:require(sys)
class MultiWiiConnection {

	public var connected(default,null) : Bool;
	public var serial(default,null) : SerialConnection;
	
	public function new( path : String ) {
		serial = new SerialConnection( path, false );
		connected = false;
	}

	public function connect() {
		serial.setup();
		connected = serial.isSetup;
	}

	public function disconnect() {
		//TODO
	}

	public function send( msp : MultiWiiProtocolCommand, ?data : String ) {
		trace( 'sending msp [$msp]' );
		serial.writeBytes( MultiWiiProtocol.createCommand( msp, data ).toString() );
		serial.flush();
	}

	public function recv() : MultiWiiProtocolPacket {
		trace( "recv msp" );
		var state = header(0);
		var pos = 0;
		var r : MultiWiiProtocolPacket = cast {}; 
		while( true ) {
			var available = serial.available();
			if( available > 0 ) {
				//trace('available:$available');
				var remain = available;
				trace("state:"+state+" / remain:"+remain);
				while( remain > 0 ) {
					switch state {
					case header(i):
						readHeaderByte(i);
						remain--;
						state = (i == 2) ? size : header(i+1);
					case size:
						r.size = serial.readByte();
						remain--;
						state = MultiWiiConnectionState.code;
					case code:
						r.code = cast serial.readByte();
						remain--;
						state = MultiWiiConnectionState.data;
					case data:
						//trace("DAAAAAAAATA size:"+r.size+" / remain:"+remain);
						if( r.size == 0 ) {
							state = checksum;
							continue;
						}
						if( r.data == null )
							r.data = Bytes.alloc(r.size);
						//var n = 0;
						while( remain > 0 ) {
						//	trace("::::"+remain);
							r.data.set( pos, serial.readByte() );
							remain--;
							pos++;
							if( pos == r.size ) {
								state = checksum;
								break;
							}
							/*
							if( r.data.length == r.size ) {
								state = checksum;
								break;
							}
							*/
						}
					case checksum:
						//TODO
						var checksum = serial.readByte();
						//trace("checksum:"+checksum);
						r.checksum = checksum;
						return r;
					}
				}
			}
		}
		return null;
	}

	function readHeaderByte( i : Int ) {
		if( serial.readByte() != MultiWiiProtocol.HEADER_B.charCodeAt(i) )
			throw 'invalid msp header';
	}

}
