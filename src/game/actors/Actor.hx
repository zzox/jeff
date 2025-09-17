package game.actors;

import core.gameobjects.Sprite;
import core.util.Util;
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

enum ActorState {
    PreAttack;
    Attack;
    Other;
}

class Actor extends Sprite {
    static inline final ATTACK_TIME:Int = 30;

    var health:Int = 100;

    public var type:ActorType;

    public var target:Actor;

    public var state:ActorState = Other;
    public var stateFrames:Int = 0;
    public var hurt(get, never):Bool;
    public var hurtFrames:Int = 0;

    public var attackAngle:Null<Float>;
    public var attackBaseX:Null<Float>;
    public var attackBaseY:Null<Float>;

    public function new (x:Float, y:Float, type:ActorType) {
        super(x, y, Assets.images.actors, 32, 32);
        this.type = type;
    }

    override function update (delta:Float) {
        super.update(delta);

        hurtFrames -= 1;

        if (type == Jeff) {
            if (hurtFrames > 30) {
                anim.play('jeff-stand');
                // anim.play('jeff-hurt');
            } else {
                x += 0.5;
                anim.play('jeff-walk');
            }
        } else if (state == PreAttack) {
            stateFrames--;
            if (stateFrames == 0) {
                state = Attack;
                if (target != null) {
                    attackBaseX = x;
                    attackBaseY = y;
                    attackAngle = angleToTarget();
                    stateFrames = ATTACK_TIME;
                } else {
                    state = Other;
                }
            }
        } else if (state == Attack) {
            stateFrames--;
            if (stateFrames == 0) {
                state = Other;
            }
            final distance = (1 - Math.abs((stateFrames / ATTACK_TIME) - 0.5) * 2) * 24;
            // 30 -> 0
            // 22 -> 0.5
            // 15 -> 1
            // 7 -> 0.5
            // 0 -> 0
            final vel = velocityFromAngle(attackAngle, distance);
            x = attackBaseX + vel.x;
            y = attackBaseY + vel.y;
        } else if (target != null) {
            final vel = velocityFromAngle(angleToTarget(), actorData[type].speed);

            x += vel.x * delta;
            y += vel.y * delta;

            if (distanceToTarget() < 16.0) {
                attack();
            }

            anim.play(actorData[type].attackAnim);
        }

        visible = hurtFrames <= 0 || Math.floor(hurtFrames / 5) % 2 == 1;
    }

    public function getHit (fromActor:ActorType) {
        if (!hurt) {
            hurtFrames = 60;
            trace('${type} hurt by ${fromActor}', hurtFrames);
        }
    }

    function attack () {
        state = PreAttack;
        stateFrames = ATTACK_TIME;
    }

    function get_hurt () {
        return hurtFrames > 0;
    }

    function distanceToTarget ():Float {
        return distanceBetween(target.getMiddleX(), target.getMiddleY(), getMiddleX(), getMiddleY());
    }

    function angleToTarget ():Float {
        return angleFromPoints(target.getMiddleX(), target.getMiddleY(), getMiddleX(), getMiddleY());
    }
}
