
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;

@:enum abstract MultiWiiProtocolCommand(Int) {

	var MSP_VERSION = 0;

	var MSP_IDENT = 100;
	var MSP_STATUS = 101;
	var MSP_RAW_IMU = 102;
	var MSP_SERVO = 103;
	var MSP_MOTOR = 104;
	var MSP_RC = 105;
	var MSP_RAW_GPS = 106;
	var MSP_COMP_GPS = 107;
	var MSP_ATTITUDE = 108;
	var MSP_ALTITUDE = 109;
	var MSP_ANALOG = 110;
	var MSP_RC_TUNING = 111;
	var MSP_PID = 112;
	var MSP_BOX = 113;
	var MSP_MISC = 114;
	var MSP_MOTOR_PINS = 115;
	var MSP_BOXNAMES = 116;
	var MSP_PIDNAMES = 117;
	var MSP_WP = 118;
	var MSP_BOXIDS = 119;
	var MSP_SERVO_CONF = 120;

	var MSP_SET_RAW_RC = 200;
	var MSP_SET_RAW_GPS = 201;
	var MSP_SET_PID = 202;
	var MSP_SET_BOX = 203;
	var MSP_SET_RC_TUNING = 204;
	var MSP_ACC_CALIBRATION = 205;
	var MSP_MAG_CALIBRATION = 206;
	var MSP_SET_MISC = 207;
	var MSP_RESET_CONF = 208;
	var MSP_SET_WP = 209;
	var MSP_SELECT_SETTING = 210;
	var MSP_SET_HEAD = 211;
	var MSP_SET_SERVO_CONF = 212;
	var MSP_SET_MOTOR = 214;

	var MSP_BIND = 240;

	var MSP_EEPROM_WRITE = 250;

	var MSP_DEBUGMSG = 253;
	var MSP_DEBUG = 254;
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

	/**
		Read MSP command data
	*/
	public static function read( msp : MultiWiiProtocolCommand, data : Bytes ) : Array<Int> {
		var r = new Array<Int>();
		var i = new BytesInput( data );
		switch msp {
		case MSP_IDENT:
			trace("MSP_IDENT");
			for( j in 0...3 ) r.push( i.readByte() );
			r.push( i.readInt16() );
		case MSP_STATUS:
			trace("MSP_STATUS");
			for( j in 0...3 ) r.push( i.readInt16() );
			r.push( i.readInt32() );
			r.push( i.readByte() );
		case MSP_RAW_IMU:
			trace( "MSP_RAW_IMU" );
			for( j in 0...9 ) r.push( i.readInt16() );
		case MSP_SERVO:
			trace("MSP_SERVO");
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case MSP_MOTOR:
			trace("MSP_MOTOR");
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case MSP_RC:
			trace("MSP_RC");
			for( n in 0...8 ) r.push( i.readUInt16() ); //TODO Docs say: 16 x UINT 16
		case MSP_RAW_GPS:
			trace("MSP_RAW_GPS");
			for( n in 0...2 ) r.push( i.readByte() );
			for( n in 0...2 ) r.push( i.readInt32() );
			for( n in 0...3 ) r.push( i.readInt16() );
		case MSP_COMP_GPS:
			trace("MSP_COMP_GPS");
			for( n in 0...2 ) r.push( i.readUInt16() );
			r.push( i.readByte() );
		case MSP_ATTITUDE:
			trace("MSP_ATTITUDE");
			var i = new BytesInput( data );
			for( n in 0...3 ) r.push( i.readInt16() );
		case MSP_ALTITUDE:
			trace("MSP_ALTITUDE");
			var i = new BytesInput( data );
			r.push( i.readInt32() );
			r.push( i.readInt16() );
		case MSP_ANALOG:
			trace("MSP_ANALOG");
			r.push( i.readByte() );
			for( j in 0...3 ) r.push( i.readUInt16() );
		case MSP_RC_TUNING:
			trace("MSP_RC_TUNING");
			for( j in 0...7 ) r.push( i.readByte() );
		case MSP_PID:
			trace("MSP_PID");
			for( j in 0...(PIDITEMS*3) ) r.push( i.readByte() );
		case MSP_BOX:
			trace("MSP_BOX");
			//TODO BOXITEMS number is dependant of multiwii configuration, BOXITEMS x UINT 16
			for( j in 0...Std.int(data.length/2) ) r.push( i.readUInt16() );
			//for( j in 0...data.length ) r.push( i.readUInt16() );
		case MSP_MISC:
			trace("MSP_MISC");
			for( j in 0...6 ) r.push( i.readUInt16() );
			r.push( i.readInt32() );
			r.push( i.readUInt16() );
			for( j in 0...4 ) r.push( i.readByte() );
		case MSP_MOTOR_PINS:
			trace("MSP_MOTOR_PINS");
			for( j in 0...8 ) r.push( i.readByte() );
		case MSP_BOXNAMES:
			trace("MSP_BOXNAMES");
			//TODO
			trace(data);
			//var s = data.toString();
			//for( j in 0...s.length ) r.push( s.charCodeAt(j) );
		case MSP_PIDNAMES:
			//TODO
			trace("MSP_PIDNAMES");
			trace(data);
		case MSP_SERVO_CONF:
			trace("MSP_SERVO_CONF");
			for( j in 0...8 ) {
				for( k in 0...3 ) r.push( i.readUInt16() );
				r.push( i.readByte() );
			}
		/*
		case MSP_WP:
			trace("MSP_WP");
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
	
	/*
	public static function read_ident( data : Bytes ) {
		var a = read( MSP_IDENT, data );
		return {
			version : a[0],
			multitype : a[1],
			msp_version : a[2],
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

}
