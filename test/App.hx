
import Sys.print;
import Sys.println;
import MultiWiiProtocol;
import MultiWiiProtocol.MultiWiiProtocolCommand;

class App extends haxe.unit.TestCase {

	static function main() {

		var path = '/dev/ttyACM0';
		var args = Sys.args();
		if( args.length > 0 )
			path = args[0];

		var cnx = new MultiWiiConnection( path );
		cnx.connect();
		if( !cnx.connected ) {
			trace('failed to connect multiwii');
			return;
		}
		println('multiwii connected');
		Sys.sleep(1);
		
		var commands = [
			MultiWiiProtocolCommand.IDENT,
			MultiWiiProtocolCommand.ATTITUDE,
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
		];

		for( cmd in commands ) {
			cnx.send( cmd );
			var packet = cnx.recv();
			var data = MultiWiiProtocol.read( packet.code, packet.data );
			println(data);
			Sys.sleep(0.2);
		}

		cnx.disconnect();
	}

}
