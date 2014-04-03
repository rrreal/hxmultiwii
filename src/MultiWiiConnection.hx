
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import MultiWiiProtocol;

enum MultiWiiConnectionState {
	header;
	size;
	code;
	data;
	checksum;
}

@:require(sys)
class MultiWiiConnection {

	public var connected(default,null) : Bool;

	var cnx : SerialConnection;
	
	public function new( path : String ) {
		cnx = new SerialConnection( path, false );
		connected = false;
	}

	public function connect() {
		cnx.setup();
		connected = cnx.isSetup;
	}

	public function disconnect() {
		//TODO
	}

	public function send( msp : MultiWiiProtocolCommand, ?data : String ) {
		trace( 'sending msp [$msp]' );
		cnx.writeBytes( MultiWiiProtocol.createCommand( msp, data ).toString() );
		cnx.flush();
	}

	public function recv() : MultiWiiProtocolPacket {
		trace( "recv msp" );
		var state = header;
		var pos = 0;
		//var size : Int = 0;
		//var code : Int = 0;
		//var data : Bytes = null;
		var r : MultiWiiProtocolPacket = cast {}; 
		while( true ) {
			var available = cnx.available();
			if( available > 0 ) {
				//trace('available:$available');
				var remain = available;
				trace("state:"+state+" / remain:"+remain);
				while( remain > 0 ) {
					switch state {
					case header:
						if( cnx.readBytes(3) != "$M>" )
							throw 'invalid header';
						remain -= 3;
						state = MultiWiiConnectionState.size;
					case size:
						r.size = cnx.readByte();
						remain--;
						state = MultiWiiConnectionState.code;
					case code:
						r.code = cast cnx.readByte();
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
							r.data.set( pos, cnx.readByte() );
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
						var checksum = cnx.readByte();
						//trace("checksum:"+checksum);
						r.checksum = checksum;
						return r;
					}
				}
			}
		}
		return null;
	}

}
