package game.actors;

import core.components.Family;
import core.components.FrameAnim;
import core.gameobjects.BitmapText;
import core.gameobjects.SImage;
import core.system.Camera;
import core.util.Util;
import game.actors.Actor;
import game.board.Board.BlockType;
import game.ui.UiText.makeSmallText;
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
                frameAnim.add('diamond', [8, 9], 15);
                frameAnim.add('diamond-move', [8, 9], 10);
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
        final actor = new Actor(x, y, type);
        final anim = animations.getNext();
        anim.active = true;
        actor.init(anim);
        actors.push(actor);
        return actor;
    }

    public function generateTeammate (type:BlockType) {
        trace('to generate: ${type}');

        final angle = aliveTime / 50;

        final vel = velocityFromAngle(angle, 32);

        makeActor(jeff.x - 16 - vel.x, jeff.y - 16 - vel.y, Bat);
    }

    public function update (delta:Float, camera:Camera) {
        aliveTime += delta;

        if (bgImage1.x + 200 <= camera.scrollX) bgImage1.x += 600;
        if (bgImage2.x + 200 <= camera.scrollX) bgImage2.x += 600;
        if (bgImage3.x + 200 <= camera.scrollX) bgImage3.x += 600;

        final goodGuys = actors.filter(a -> { goodTypes.contains(a.type); }).filter(a -> !a.dead);
        final badGuys = actors.filter(a -> { badTypes.contains(a.type); }).filter(a -> !a.dead);

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

        for (i in 0...actors.length) actors[i].update(delta);
        animations.update(delta);

        // TODO: combine, use int iterator
        for (a in actors) {
            if (a.damaged > 0) {
                makeDamageNumber(Math.floor(a.x + 16), Math.floor(a.y), a.damaged);
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
        final shadowIndex = 16;

        for (i in 0...actors.length) {
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
