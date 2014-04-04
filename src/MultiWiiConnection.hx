
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

	/**
		Create and send msp packet.
	*/
	public function send( msp : MultiWiiProtocolCommand, ?data : String, flush = false ) {
		if( !connected )
			throw 'not connected';
		serial.writeBytes( MultiWiiProtocol.create( msp, data ).toString() );
		if( flush ) serial.flush();
	}

	/**
		Read a msp packet from serial connection.
	*/
	public function recv() : MultiWiiProtocolPacket {
		var state = header(0);
		var p : MultiWiiProtocolPacket = { size : null, code : null, data : null, checksum : 0 }; 
		var packetPos = 0;
		while( true ) {
			var available = serial.available();
			if( available > 0 ) {
				var pos = 0;
				//trace( 'available:$available' );
				while( pos < available ) {
					//trace("state:"+state+'( pos:$pos, available:$available )' );
					switch state {
					case header(i):
						var c = serial.readByte();
						if( c != MultiWiiProtocol.HEADER_B.charCodeAt(i) ) {
							if( i == 2 && String.fromCharCode(c) == "!" ) {
								//TODO protocol error
								trace("TODO protocol error");
							}
							throw 'invalid msp header ($i)';
						}
						state = (i < 2) ? header(i+1) : size;
					case size:
						p.size = serial.readByte();
						state = code;
						p.checksum ^= (p.size & 0xff);
					case code:
						var msp = serial.readByte();
						p.code = cast msp;
						p.checksum ^= (msp & 0xff);
						state = (p.size == 0) ? checksum : data;
						if( p.size == 0 )
							state = checksum;
						else {
							p.data = Bytes.alloc( p.size );
							state = data;
						}
					case data:
						var c = serial.readByte();
						p.data.set( packetPos-5, c );
						p.checksum ^= (c & 0xff);
						if( packetPos-4 == p.size ) state = checksum;
					case checksum:
						var sum = serial.readByte();
						//trace( "checksum: "+sum+":"+p.checksum );
						if( sum != p.checksum ) {
							//TODO
							trace("\tWARNING! INVALID CHECKSUM" );
						}
						return p;
					}
					pos++;
					packetPos++;
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
