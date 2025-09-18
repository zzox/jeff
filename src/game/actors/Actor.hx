package game.actors;

import core.gameobjects.Sprite;
import core.system.Camera;
import core.util.Util;
import kha.Assets;
import kha.graphics2.Graphics;

enum ActorType {
    Jeff;
    Diamond;
    Fly;
    Bat;
}

typedef ActorData = {
    var anim:String;
    var attackAnim:String;
    var health:Int;
    var damage:Int;
    var bodyX:Int;
    var bodyY:Int;
    var offsetX:Int;
    var offsetY:Int;
    var speed:Float;
    var shadowSize:Int;
}

final actorData:Map<ActorType, ActorData> = [
Jeff => {
    anim: 'jeff-walk',
    attackAnim: '',
    health: 100,
    damage: 0,
    bodyX: 10,
    bodyY: 10,
    offsetX: 11,
    offsetY: 10,
    speed: 60.0,
    shadowSize: 4
}, Diamond => {
    anim: 'diamond',
    attackAnim: 'diamond',
    health: 30,
    damage: 6,
    bodyX: 10,
    bodyY: 10,
    offsetX: 11,
    offsetY: 10,
    speed: 45.0,
    shadowSize: 3
}, Bat => {
    anim: 'bat',
    attackAnim: 'bat',
    health: 20,
    damage: 6,
    bodyX: 8,
    bodyY: 8,
    offsetX: 12,
    offsetY: 11,
    speed: 50.0,
    shadowSize: 2
}
];

final goodTypes = [Jeff, Fly, Bat];
final badTypes = [Diamond];

enum ActorState {
    PreAttack;
    Attack;
    Dead;
    Other;
}

class Actor extends Sprite {
    static inline final ATTACK_TIME:Int = 15;

    public var type:ActorType;
    public var health:Int;
    public var target:Actor;

    public var state:ActorState;
    public var stateFrames:Int;
    public var hurt(get, never):Bool;
    public var dead(get, never):Bool;
    public var hurtFrames:Int;

    public var attackAngle:Null<Float>;
    public var attackBaseX:Null<Float>;
    public var attackBaseY:Null<Float>;

    public var guardX:Null<Float>;
    public var guardY:Null<Float>;

    public var deadIndex:Null<Int>;
    public var damaged:Int;

    // jeff specific stuff
    public var isJeffMoving:Bool;

    public function new (x:Float, y:Float) {
        super(x, y, Assets.images.actors, 32, 32);
    }

    public function startActor (type:ActorType) {
        this.type = type;
        health = actorData[type].health;

        state = Other;
        stateFrames = 0;
        hurtFrames = 0;

        target = null;
        attackAngle = null;
        attackBaseX = null;
        attackBaseY = null;

        deadIndex = null;

        damaged = 0;

        // jeff specific stuff
        isJeffMoving = false;

        anim.play(actorData[type].anim);
    }

    override function update (delta:Float) {
        super.update(delta);

        hurtFrames--;

        if (state == Dead) {
        } else if (type == Jeff) {
            if (hurtFrames > 30) {
                anim.play('jeff-stand');
                // anim.play('jeff-hurt');
            } else if (isJeffMoving) {
                // x += 0.5;
                x += 0.125;
                anim.play('jeff-walk');
            } else {
                anim.play('jeff-stand');
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
            } else if (stateFrames == Math.ceil(ATTACK_TIME / 2)) {
                if (target == null) {
                    throw 'Null enemy?';
                }

                target.getHit(type);
            }

            final attackDistance = 12; // how far the actor moves
            final distance = (1 - Math.abs((stateFrames / ATTACK_TIME) - 0.5) * 2) * attackDistance;
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
        } else if (goodTypes.contains(type)) {
            if (Math.abs(x - guardX) > 1 || Math.abs(y - guardY) > 1) {
                final vel = velocityFromAngle(angleToGuard(), actorData[type].speed);

                x += vel.x * delta;
                y += vel.y * delta;
            }
        }

        visible = hurtFrames <= 0 || Math.floor(hurtFrames / 3) % 2 == 1;
    }

    public function getHit (fromActor:ActorType) {
        final damage = 5;

        // if (!hurt) {
            hurtFrames = 30;
            trace('${type} hurt by ${fromActor}', hurtFrames);
            health -= damage;

            damaged = damage;
        // }
    }

    function attack () {
        state = PreAttack;
        stateFrames = ATTACK_TIME;
        trace('${type} attacking');
    }

    public function die () {
        state = Dead;
        color = 0x000000;
        deadIndex = tileIndex;
        trace('${type} dead');
    }

    public function destroy () {
        stop();
        anim.active = false;
    }

    function get_hurt () {
        return hurtFrames > 0;
    }

    function get_dead () {
        return state == Dead;
    }

    function distanceToTarget ():Float {
        return distanceBetween(target.getMiddleX(), target.getMiddleY(), getMiddleX(), getMiddleY());
    }

    function angleToTarget ():Float {
        return angleFromPoints(target.getMiddleX(), target.getMiddleY(), getMiddleX(), getMiddleY());
    }

    function angleToGuard ():Float {
        return angleFromPoints(guardX, guardY, x, y);
    }

    override function render (g2:Graphics, cam:Camera) {
        if (deadIndex != null) tileIndex = deadIndex;
        super.render(g2, cam);
    }
}
