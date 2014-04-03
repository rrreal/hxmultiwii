
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import MultiWiiProtocol;

private enum MultiWiiConnectionState {
	header(i:Int);
	size;
	code;
	data;
	checksum;
	//error(i:Int);
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
		serial.close();
		connected = false;
	}

	public function send( msp : MultiWiiProtocolCommand, ?data : String, flush = true ) {
		//trace( 'send msp [$msp]' );
		serial.writeBytes( MultiWiiProtocol.create( msp, data ).toString() );
		if( flush ) serial.flush();
	}

	public function recv() : MultiWiiProtocolPacket {
		//trace( "recv msp" );
		var r : MultiWiiProtocolPacket = { size : null, code : null, data : null, checksum : 0 }; 
		var data_pos = 0;
		var state = header(0);
		while( true ) {
			var available = serial.available();
			if( available > 0 ) {
			//	trace('available:$available');
				var remain = available;
				while( remain > 0 ) {
				//	trace("state:"+state+" / remain:"+remain);
					switch state {
					/*
					case error(i):
						var c = serial.readByte();
						if( i == 2 ) {
							state = header(0);
						}
					*/
					case header(i):
						var c = serial.readByte();
						remain--;
						if( c != MultiWiiProtocol.HEADER_B.charCodeAt(i) ) {
							//TODO
							if( i == 2 && String.fromCharCode(c) == "!" ) {
								trace("TODO ERROR");
								//trace(serial.readByte()); // 0
								//trace(serial.readByte()); //  [unknown code]
								//trace(serial.readByte()); // [checksum]
								//state = header(0);
								//state = error(0);
								return null;
							}

							throw 'invalid msp header ($i)';
						}
						state = (i < 2) ? header(i+1) : size;
					case size:
						r.size = serial.readByte();
						remain--;
						r.checksum ^= (r.size & 0xff);
						state = code;
					case code:
						var msp = serial.readByte();
						remain--;
						r.code = cast msp;
						r.checksum ^= (msp & 0xff);
						state = (r.size == 0) ? checksum : data;
					case data:
						if( r.data == null )
							r.data = Bytes.alloc(r.size);
						while( remain > 0 ) {
							var c = serial.readByte();
							remain--;
							r.checksum ^= (c & 0xff);
							r.data.set( data_pos, c );
							if( ++data_pos == r.size ) {
								state = checksum;
								break;
							}
						}
					case checksum:
						var cs = serial.readByte();
						remain--;
						if( r.checksum != cs ) {
							//TODO
							trace("CHECKSUM FAILED! "+r.checksum+"="+cs );
					//		throw 'invalid checksum';
						}
						r.checksum = cs;
						return r;
					}
				}
			}
		}
		return null;
	}

	/*
	public function request_ident() {
		send( MSP_IDENT );
		return MultiWiiProtocol.read_ident( recv().data );
	}

	public function request_status() {
		send( MSP_STATUS );
		return MultiWiiProtocol.read_status( recv().data );
	}
	*/

}
