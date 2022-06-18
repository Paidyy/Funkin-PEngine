package;

class Boyfriend extends Character {
	public function new(x:Float, y:Float, ?char:String = 'bf', forceCache:Bool = false) {
		super(x, y, char, true, false, forceCache);
	}
}
