
import Sys.println;
import MultiWiiProtocol;

class App extends haxe.unit.TestCase {

	static var cnx : MultiWiiConnection;

	static function sendRecvPacket<T>( msp : MultiWiiProtocolCommand ) {
		cnx.send( msp );
		var packet = cnx.recv();
		if( packet == null )
			return null;
		return MultiWiiProtocol.read( packet.code, packet.data );
	}

	static function main() {

		var path = '/dev/ttyACM0';
		var args = Sys.args();
		if( args.length > 0 )
			path = args[0];

		cnx = new MultiWiiConnection( path );
		cnx.connect();
		if( !cnx.connected ) {
			trace('failed to connect multiwii');
			return;
		}
		println('multiwii connected');
		Sys.sleep(1);
		
		var commands = [
			MultiWiiProtocolCommand.IDENT,
			MultiWiiProtocolCommand.STATUS,
			MultiWiiProtocolCommand.RAW_IMU,
			MultiWiiProtocolCommand.SERVO,
			MultiWiiProtocolCommand.MOTOR,
			MultiWiiProtocolCommand.RC,
		//	MultiWiiProtocolCommand.RAW_GPS,
		//	MultiWiiProtocolCommand.COMP_GPS,
			MultiWiiProtocolCommand.ATTITUDE,
			MultiWiiProtocolCommand.ALTITUDE,
			MultiWiiProtocolCommand.ANALOG,
			MultiWiiProtocolCommand.RC_TUNING,
			MultiWiiProtocolCommand.PID,
			MultiWiiProtocolCommand.BOX,
			MultiWiiProtocolCommand.MISC,
			MultiWiiProtocolCommand.MOTOR_PINS,
			MultiWiiProtocolCommand.BOXNAMES,
			MultiWiiProtocolCommand.PIDNAMES,
		//	MultiWiiProtocolCommand.WP,
			MultiWiiProtocolCommand.BOXIDS,
			MultiWiiProtocolCommand.SERVO_CONF
			
			//MultiWiiProtocolCommand.MSP_UUU

		];

		for( cmd in commands ) {
			println( sendRecvPacket( cmd ) );
			Sys.sleep(0.3);
		}
	}

}
