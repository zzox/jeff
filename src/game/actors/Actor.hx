package game.actors;

import core.gameobjects.Sprite;
import core.util.Util.angleFromPoints;
import core.util.Util.velocityFromAngle;
import kha.Assets;

enum ActorType {
    Jeff;
    Diamond;
    Fly;
}

typedef ActorData = {
    var anim:String;
    var attackAnim:String;
    var bodyX:Int;
    var bodyY:Int;
    var offsetX:Int;
    var offsetY:Int;
    var speed:Float;
}

final actorData:Map<ActorType, ActorData> = [
Jeff => {
    anim: 'jeff-walk',
    attackAnim: '',
    bodyX: 10,
    bodyY: 10,
    offsetX: 11,
    offsetY: 10,
    speed: 60.0
}, Diamond => {
    anim: 'diamond',
    attackAnim: 'diamond',
    bodyX: 10,
    bodyY: 10,
    offsetX: 11,
    offsetY: 10,
    speed: 60.0
}
];

final goodTypes = [Jeff, Fly];
final badTypes = [Diamond];

class Actor extends Sprite {
    var health:Int;

    public var type:ActorType;

    public var target:Actor;

    public function new (x:Float, y:Float, type:ActorType) {
        super(x, y, Assets.images.actors, 32, 32);
        this.type = type;
    }

    override function update (delta:Float) {
        super.update(delta);

        if (type == Jeff) {
            x += 0.5;
            anim.play('jeff-walk');
        } else if (target != null) {
            final vel = velocityFromAngle(
                angleFromPoints(
                    target.getMiddleX(),
                    target.getMiddleY(),
                    getMiddleX(),
                    getMiddleY()
                ),
                actorData[type].speed
            );

            x += vel.x * delta;
            y += vel.y * delta;

            anim.play(actorData[type].attackAnim);
        }
    }
}

