package game.actors;

import core.gameobjects.GameObject;
import core.system.Camera;
import core.util.Util;
import kha.Assets;
import kha.graphics2.Graphics;

class SpawnParticle extends GameObject {
    var velX:Float;
    var velY:Float;
    var targetX:Float;
    var targetY:Float;
    var speed:Float;

    var aliveFrames:Int;
    var moveFrames:Int;

    public function new () {
        x = -512;
        y = -512;

        setScrollFactor(0, 0);

        stop();
    }

    public function spawn (x:Float, y:Float, targetX:Float, targetY:Float, color:Int) {
        this.color = color;
        this.x = x;
        this.y = y;

        aliveFrames = 0;
        moveFrames = 60 + randomInt(30);
        final vel = velocityFromAngle(Math.random() * 360, 100);

        velX = vel.x;
        velY = vel.y;

        this.targetX = targetX;
        this.targetY = targetY;

        speed = 0;

        start();
    }

    override function update (delta:Float) {
        if (aliveFrames < moveFrames) {
            velX *= 0.9;
            velY *= 0.9;

            x += velX * delta;
            y += velY * delta;
        } else if (distanceBetween(targetX, targetY, x, y) < speed * delta) {
            // x = targetX;
            // y = targetY;
            stop();
        } else {
            speed += 10;

            final vel = velocityFromAngle(angleFromPoints(targetX, targetY, x, y), speed);

            x += vel.x * delta;
            y += vel.y * delta;
        }

        aliveFrames++;

        if (aliveFrames == 120) {
            stop();
        }
    }

    override function render (g2:Graphics, camera:Camera) {
        // TODO: move these to inlined pre and post render?
        g2.pushTranslation(-camera.scrollX * scrollFactorX, -camera.scrollY * scrollFactorY);
        g2.pushScale(camera.scale, camera.scale);
        g2.color = Math.floor(255 * alpha) * 0x1000000 | color;

        g2.drawImage(Assets.images.particle, x, y);

        g2.popTransformation();
        g2.popTransformation();
    }
}
