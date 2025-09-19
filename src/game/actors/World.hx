package game.actors;

import core.components.Family;
import core.components.FrameAnim;
import core.gameobjects.BitmapText;
import core.gameobjects.SImage;
import core.system.Camera;
import core.util.Util;
import game.actors.Actor;
import game.ui.UiText;
import haxe.ds.ArraySort;
import kha.Assets;
import kha.graphics2.Graphics;

class Anims extends Family<FrameAnim> {
    public function new () {
        super((num:Int) -> {
            return [for (_ in 0...num) {
                final frameAnim = new FrameAnim();
                frameAnim.add('jeff-stand', [0]);
                frameAnim.add('jeff-walk', [1, 2, 0, 3, 4, 0], 10);
                frameAnim.add('bat', [5, 6, 7], 15);
                frameAnim.add('blob', [10, 11, 12], 15);
                frameAnim.add('fly', [13, 14], 5);
                frameAnim.add('diamond', [15, 16], 15);
                frameAnim.add('diamond-move', [15, 16], 10);
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
    var bgImage1:SImage;
    var bgImage2:SImage;
    var bgImage3:SImage;

    var animations:Anims;
    var actors:Array<Actor> = [];
    public var jeff:Actor;

    final damageNumbers:Array<BitmapText> = [];

    public var aliveTime:Float = 0.0;

    public function new () {
        bgImage1 = new SImage(-100, -56, Assets.images.ground_bg);
        bgImage2 = new SImage(-100 + 200, -56, Assets.images.ground_bg);
        bgImage3 = new SImage(-100 + 400, -56, Assets.images.ground_bg);

        animations = new Anims();
        jeff = makeActor(0, 0, Jeff);

        makeActor(120, 0, Diamond);

        for (_ in 0...20) {
            final damageNumber = makeSmallText(-16, -16, '');
            damageNumber.color = 0xbe2633;
            damageNumbers.push(damageNumber);
        }
    }

    function makeActor (x:Float, y:Float, type:ActorType) {
        final actor = new Actor(x, y);
        final anim = animations.getNext();
        anim.active = true;
        actor.init(anim);
        actor.startActor(type);
        actors.push(actor);
        return actor;
    }

    public function generateTeammate (type:ActorType):Actor {
        trace('to generate: ${type}');

        final angle = aliveTime * 50;
        final vel = velocityFromAngle(angle, 32);

        return makeActor(jeff.x - vel.x, jeff.y - vel.y, Bat);
    }

    public function update (delta:Float, camera:Camera) {
        aliveTime += delta;

        if (Math.random() < 0.001) {
            makeActor(camera.scrollX + camera.width, -60 + Math.random() * 120, Diamond);
        }

        if (bgImage1.x + 200 <= camera.scrollX) bgImage1.x += 600;
        if (bgImage2.x + 200 <= camera.scrollX) bgImage2.x += 600;
        if (bgImage3.x + 200 <= camera.scrollX) bgImage3.x += 600;

        final goodGuys = actors.filter(a -> { goodTypes.contains(a.type); }).filter(a -> { return !a.dead && a.state != Spawn; });
        final badGuys = actors.filter(a -> { badTypes.contains(a.type); }).filter(a -> { return !a.dead && a.state != Spawn; });

        // sort so the ring doesn't get out of whack
        ArraySort.sort(goodGuys, ((a, b) -> a.liveFrames - b.liveFrames));

        // clear dead targets
        // don't update stuff if attacking

        // find teammates targets
        for (g in goodGuys) {
            if (g.type == Jeff) continue;

            var dist = 100.0;
            if (g.target != null) {
                dist = distanceBetween(g.getMiddleX(), g.getMiddleY(), g.target.getMiddleX(), g.target.getMiddleY());
            }

            for (b in badGuys) {
                final d = distanceBetween(g.getMiddleX(), g.getMiddleY(), b.getMiddleX(), b.getMiddleY());
                if (d < dist) {
                    g.target = b;
                    dist = d;
                }
            }
        }

        // find enemies targets
        for (b in badGuys) {
            var dist = 100.0;
            if (b.target != null) {
                dist = distanceBetween(b.getMiddleX(), b.getMiddleY(), b.target.getMiddleX(), b.target.getMiddleY());
            }

            for (g in goodGuys) {
                final d = distanceBetween(b.getMiddleX(), b.getMiddleY(), g.getMiddleX(), g.getMiddleY());
                if (d < dist) {
                    b.target = g;
                    dist = d;
                }
            }
        }

        // for (g in goodGuys) {
        //     if (g.state == Attack) {
        //         for (b in badGuys) {
        //             final gData = actorData[g.type];
        //             final bData = actorData[b.type];
        //             if (rectOverlap(
        //                 g.x + gData.offsetX,
        //                 g.y + gData.offsetY,
        //                 gData.bodyX,
        //                 gData.bodyY,
        //                 b.x + bData.offsetX,
        //                 b.y + bData.offsetY,
        //                 bData.bodyX,
        //                 bData.bodyY,
        //             )) {
        //                 b.getHit(g.type);
        //             }
        //         }
        //     }
        // }

        // for (b in badGuys) {
        //     if (b.state == Attack) {
        //         for (g in goodGuys) {
        //             final bData = actorData[b.type];
        //             final gData = actorData[g.type];
        //             if (rectOverlap(
        //                 b.x + bData.offsetX,
        //                 b.y + bData.offsetY,
        //                 bData.bodyX,
        //                 bData.bodyY,
        //                 g.x + gData.offsetX,
        //                 g.y + gData.offsetY,
        //                 gData.bodyX,
        //                 gData.bodyY
        //             )) {
        //                 g.getHit(b.type);
        //             }
        //         }
        //     }
        // }

        // if good guys don't have a target, find their point
        for (i in 0...goodGuys.length) {
            // TODO: two rings?
            final angleDiff = i / (goodGuys.length - 1) * 360;
            final vel = velocityFromAngle(aliveTime * 50 + angleDiff, 32);

            goodGuys[i].guardX = jeff.x + vel.x;
            goodGuys[i].guardY = jeff.y + vel.y;
        }

        for (i in 0...actors.length) actors[i].update(delta);
        animations.update(delta);

        // TODO: combine, use int iterator
        for (a in actors) {
            if (a.damaged > 0) {
                makeDamageNumber(Math.floor(a.x + 16), Math.floor(a.y + 16), a.damaged);
                a.damaged = 0;
            }
        }

        for (a in actors) {
            if (a.health <= 0 && !a.dead) {
                a.die();
            }
        }

        for (a in actors) {
            if (a.target?.dead) {
                a.target = null;
            }
        }

        final before = actors.length;
        actors = actors.filter(a -> {
            return a.x >= camera.scrollX;
        });
        if (actors.length != before) trace('lost ${before - actors.length}');

        ArraySort.sort(actors, (a, b) -> { return Math.floor(a.y) - Math.floor(b.y); });

        for (d in damageNumbers) {
            d.y -= 0.25;
        }
    }

    var damageNumIndex = -1;
    function makeDamageNumber (x:Int, y:Int, amount:Int) {
        final num = damageNumbers[(++damageNumIndex % damageNumbers.length)];

        num.setText(amount + '');
        num.x = Math.floor(x - num.textWidth / 2);
        num.y = y;
    }

    public function render (g2:Graphics, cam:Camera) {
        bgImage1.render(g2, cam);
        bgImage2.render(g2, cam);
        bgImage3.render(g2, cam);

        g2.pushTranslation(-cam.scrollX, -cam.scrollY);

        final image = Assets.images.actors;
        final sizeX = 32;
        final sizeY = 32;
        final shadowIndex = 25;

        for (i in 0...actors.length) {
            if (actors[i].state == Spawn) continue;

            final tileIndex = shadowIndex - actorData[actors[i].type].shadowSize;
            g2.color = 64 * 0x1000000 + 0xffffff;
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
        for (a in actors) if (a.visible) a.render(g2, cam);

        for (d in damageNumbers) if (d.visible) d.render(g2, cam);
    }
}
