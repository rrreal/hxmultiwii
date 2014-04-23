
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;

@:enum abstract MultiWiiProtocolCommand(Int) {

	var VERSION = 0;

	var IDENT = 100;
	var STATUS = 101;
	var RAW_IMU = 102;
	var SERVO = 103;
	var MOTOR = 104;
	var RC = 105;
	var RAW_GPS = 106;
	var COMP_GPS = 107;
	var ATTITUDE = 108;
	var ALTITUDE = 109;
	var ANALOG = 110;
	var RC_TUNING = 111;
	var PID = 112;
	var BOX = 113;
	var MISC = 114;
	var MOTOR_PINS = 115;
	var BOXNAMES = 116;
	var PIDNAMES = 117;
	var WP = 118;
	var BOXIDS = 119;
	var SERVO_CONF = 120;

	var SET_RAW_RC = 200;
	var SET_RAW_GPS = 201;
	var SET_PID = 202;
	var SET_BOX = 203;
	var SET_RC_TUNING = 204;
	var ACC_CALIBRATION = 205;
	var MAG_CALIBRATION = 206;
	var SET_MISC = 207;
	var RESET_CONF = 208;
	var SET_WP = 209;
	var SELECT_SETTING = 210;
	var SET_HEAD = 211;
	var SET_SERVO_CONF = 212;
	var SET_MOTOR = 214;

	var BIND = 240;

	var EEPROM_WRITE = 250;

	var DEBUGMSG = 253;
	var DEBUG = 254;

	#if baseflight // Additional baseflight commands that are not compatible with MultiWii
	var UID = 160, // Unique device ID
	var ACC_TRIM = 240, // get acc angle trim values
	var SET_ACC_TRIM = 239, // set acc angle trim values
	var GPSSVINFO = 164  // get Signal Strength (only U-Blox)
	#end
}

/*
@:enum abstract MultiCopterType(Int) {
	var tri = 1;
	var quadp = 2;
	var quadx = 3;
	var bi = 4;
	var gimbal = 5;
	var y6 = 6;
	var hex6 = 7;
	var flying_wing = 8;
	var y4 = 9;
	var hex6x = 10;
	var octox8 = 11;
	var octoflatp = 12;
	var octoflatx = 13;
	var airplane = 14;
	var heli_120 = 15;
	var heli_90 = 16;
	var vtail4 = 17;
	var hex6h = 18;
	var singlecopter = 19;
	var dualcopter = 20;
}
*/

typedef MultiWiiProtocolPacket = {
	var size : UInt;
	var code : MultiWiiProtocolCommand;
	@:optional var data : Bytes;
	var checksum : Int;
}

/**
	http://www.multiwii.com/wiki/index.php?title=Multiwii_Serial_Protocol
*/
class MultiWiiProtocol {

	public static inline var HEADER_A = "$M<"; // FC->PC
	public static inline var HEADER_B = "$M>"; // PC->FC
	public static inline var PIDITEMS = 10;

	/**
		Create MSP command
	*/
	public static function create( msp : MultiWiiProtocolCommand, ?data : String ) : Bytes {
		var imsp : Int = cast msp;
		var checksum = 0;
		var size : Int = ( (data != null) ? data.length : 0 ) & 0xff;
		var buf = new BytesBuffer();
		buf.add( Bytes.ofString( HEADER_A ) );
		buf.addByte( size );
		checksum ^= (size & 0xff);
		buf.addByte( imsp & 0xff );
		checksum ^= (imsp & 0xff);
		if( data != null ) {
			for( i in 0...data.length ) {
				var c = data.charCodeAt( i );
				buf.addByte( c & 0xff );
				checksum ^= (c & 0xff);
			}
		}
		buf.addByte( checksum );
		return buf.getBytes();
	}

	//public static function read_ident( data : Bytes ) : Array<Int> {
	
	/**
		Read MSP command data
	*/
	public static function read( msp : MultiWiiProtocolCommand, data : Bytes ) : Array<Int> {
		var r = new Array<Int>();
		var i = new BytesInput( data );
		switch msp {
		case IDENT:
			for( j in 0...3 ) r.push( i.readByte() );
			r.push( i.readInt16() );
		case STATUS:
			for( j in 0...3 ) r.push( i.readInt16() );
			r.push( i.readInt32() );
			r.push( i.readByte() );
		case RAW_IMU:
			for( j in 0...9 ) r.push( i.readInt16() );
		case SERVO:
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case MOTOR:
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case RC:
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case RAW_GPS:
			for( n in 0...2 ) r.push( i.readByte() );
			for( n in 0...2 ) r.push( i.readInt32() );
			for( n in 0...3 ) r.push( i.readInt16() );
		case COMP_GPS:
			for( n in 0...2 ) r.push( i.readUInt16() );
			r.push( i.readByte() );
		case ATTITUDE:
			var i = new BytesInput( data );
			for( n in 0...3 ) r.push( i.readInt16() );
		case ALTITUDE:
			var i = new BytesInput( data );
			r.push( i.readInt32() );
			r.push( i.readInt16() );
		case ANALOG:
			r.push( i.readByte() );
			for( j in 0...3 ) r.push( i.readUInt16() );
		case RC_TUNING:
			for( j in 0...7 ) r.push( i.readByte() );
		case PID:
			for( j in 0...(PIDITEMS*3) ) r.push( i.readByte() );
		case BOX:
			//TODO BOXITEMS number is dependant of multiwii configuration, BOXITEMS x UINT 16
			for( j in 0...Std.int(data.length/2) ) r.push( i.readUInt16() );
			//for( j in 0...data.length ) r.push( i.readUInt16() );
		case MISC:
			for( j in 0...6 ) r.push( i.readUInt16() );
			r.push( i.readInt32() );
			r.push( i.readUInt16() );
			for( j in 0...4 ) r.push( i.readByte() );
		case MOTOR_PINS:
			//trace("MOTOR_PINS");
			for( j in 0...8 ) r.push( i.readByte() );
		case BOXNAMES:
			//TODO
			//return data.toString();
			var s = data.toString();
			for( j in 0...s.length ) r.push( s.charCodeAt(j) );
		case PIDNAMES:
			//TODO
			//return data.toString();
			var s = data.toString();
			for( j in 0...s.length ) r.push( s.charCodeAt(j) );
		case SERVO_CONF:
			for( j in 0...8 ) {
				for( k in 0...3 ) r.push( i.readUInt16() );
				r.push( i.readByte() );
			}
		case SET_RAW_RC:
			
		/*
		case WP:
			trace("WP");
			trace( i.readByte() );
			trace( i.readInt32() );
			trace( i.readInt32() );
			trace( i.readInt32() );
			trace( i.readUInt16() );
			trace( i.readUInt16() );
			trace( i.readByte() );
		*/
		default:
			return null;
		}
		return r;
	}

	public static inline function readPacket( packet : MultiWiiProtocolPacket ) : Dynamic {
		return read( packet.code, packet.data );
	}
	
	/*
	public static function read_ident( data : Bytes ) {
		var a = read( IDENT, data );
		return {
			version : a[0],
			multitype : a[1],
			version : a[2],
			capability : a[3]
		};
	}

	public static function read_status( data : Bytes ) {
		var a = read( MSP_STATUS, data );
		return {
			cycleTime : a[0],
			i2c_errors_count : a[1],
			sensor : a[2],
			flag : a[3],
				global_conf_currentSet : a[4]
		};
	}
	*/

	public static function read_motor_pins( data : Bytes ) : Array<Int> {
		var i = new BytesInput( data );
		var pins = new Array<Int>();
		for( _ in 0...8 ) pins.push( i.readByte() );
		return pins;
	}

}
