package game.actors;

import core.gameobjects.Sprite;
import kha.Assets;

class Actor extends Sprite {
    var health:Int;

    public function new () {
        super(x, y, Assets.images.actors, 32, 32);
    }

    override function update (delta:Float) {
        super.update(delta);

        x += 0.5;

        anim.play('jeff-walk');
    }
}

