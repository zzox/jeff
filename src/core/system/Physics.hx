package core.system;

import core.components.Family;
import core.components.PhysicsBody;

class Physics extends Family<PhysicsBody> {
    public var gravityX:Float = 0.0;
    public var gravityY:Float = 0.0;
    
    public function new (?initialNum:Int) {
        super((num:Int) -> {
            return [for (i in 0...num) new PhysicsBody(0, 0, 16, 16)];
        }, initialNum);
    }

    override function update (delta:Float) {
        for (i in 0...items.length) {
            items[i].gravityX = gravityX;
            items[i].gravityY = gravityY;
            items[i].update(delta);
        }
    }
}
