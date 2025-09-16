package game.actors;

import core.Game;
import core.components.Family;
import core.components.FrameAnim;
import core.system.Camera;
import game.actors.Actor;
import game.board.Board;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

class Anims extends Family<FrameAnim> {
    public function new () {
        super((num:Int) -> {
            return [for (_ in 0...num) {
                final frameAnim = new FrameAnim();
                frameAnim.add('jeff-stand', [0]);
                frameAnim.add('jeff-walk', [0, 1, 2, 0, 3, 4], 10);
                frameAnim.active = false;
                frameAnim;
            }];
        }, 50);
    }

    override function update (delta:Float) {
        // for (a in items) if (a.active) a.update(delta);
        // null check in FrameAnim for now
        for (a in items) a.update(delta);
    }
}

class World {
    var animations:Anims;
    var actors:Array<Actor> = [];
    public var jeff:Actor;

    public function new () {
        animations = new Anims();
        jeff = makeActor();
    }

    function makeActor () {
        final actor = new Actor();
        final anim = animations.getNext();
        anim.active = true;
        actor.init(anim);
        actors.push(actor);
        return actor;
    }

    public function update (delta:Float) {
        animations.update(delta);
        for (i in 0...actors.length) actors[i].update(delta);
    }

    public function render (g2:Graphics, cam:Camera) {
        g2.pushTranslation(-cam.scrollX, -cam.scrollY);

        final image = Assets.images.actors;
        final sizeX = 32;
        final sizeY = 32;

        for (i in 0...actors.length) {
            final tileIndex = 9;
            g2.color = 128 * 0x1000000 + 0xffffff;
            final cols = Std.int(image.width / 32);
            g2.drawScaledSubImage(
                image,
                (tileIndex % cols) * sizeX,
                Math.floor(tileIndex / cols) * sizeY,
                sizeX,
                sizeY,
                Math.floor(actors[i].x/* + (flipX ? sizeX : 0)*/),
                Math.floor(actors[i].y/* + (flipY ? sizeY : 0)*/),
                sizeX,// * (flipX ? -1 : 1),
                sizeY// * (flipY ? -1 : 1)
            );
    
        }

        g2.popTransformation();

        g2.color = 0xffffffff;
        for (a in actors) a.render(g2, cam);
    }
}
