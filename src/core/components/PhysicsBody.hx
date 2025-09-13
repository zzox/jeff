package core.components;

import core.Types;
import core.util.Util;

// TODO: mass
class PhysicsBody extends Component {
    public var x:Float;
    public var y:Float;
    // previous position of this body
    public var lastX:Float;
    public var lastY:Float;

    public var sizeX:Int;
    public var sizeY:Int;

    // If this can be effected by other physics body.
    // public var immovable:Bool = false;

    public var gravityX:Float = 0.0;
    public var gravityY:Float = 0.0;

    // The multiplier in which gravity effects this body.
    public var gravityFactorX:Float = 1.0;
    public var gravityFactorY:Float = 1.0;

    // The increase of velocity per second.
    public var accX:Float = 0.0;
    public var accY:Float = 0.0;

    // The movement of pixels per second.
    public var velX:Float = 0.0;
    public var velY:Float = 0.0;

    // Maximum velocity.
    public var maxVelX:Float = 0.0;
    public var maxVelY:Float = 0.0;

    // The decrease of velocity per second.
    public var dragX:Float = 0.0;
    public var dragY:Float = 0.0;
    
    // 0 for no bounce, 1 to retain all velocity
    public var bounceX:Float = 0.0;
    public var bounceY:Float = 0.0;

    // Boolean values of 4 cardinal directions, true if they are touching
    // another physics body. Set from Physics System
    public var touchingLeft:Bool = false;
    public var touchingRight:Bool = false;
    public var touchingUp:Bool = false;
    public var touchingDown:Bool = false;

    // Boolean values of 4 cardinal directions, true if they allow collisions
    // from a direction.
    public var collidesLeft:Bool = true;
    public var collidesRight:Bool = true;
    public var collidesUp:Bool = true;
    public var collidesDown:Bool = true;

    public function new (x:Float, y:Float, sizeX:Int, sizeY:Int) {
        super();

        this.x = x;
        this.y = y;
        this.sizeX = sizeX;
        this.sizeY = sizeY;
        this.lastX = x;
        this.lastY = y;
    }

    // Update this physics body with the time since the last update.
    override function update (delta:Float) {
        final posX = x;
        final posY = y;

        // calculate increase/decrease velocity based on gravity and acceleration
        var newX = velX + delta * (accX + (gravityX * gravityFactorX));
        var newY = velY + delta * (accY + (gravityY * gravityFactorY));

        // subtract drag
        if (newX > 0) {
            newX = Math.max(0, newX - dragX * delta);
        }

        if (newX < 0) {
            newX = Math.min(0, newX + dragX * delta);
        }

        if (newY > 0) {
            newY = Math.max(0, newY - dragY * delta);
        }

        if (newY < 0) {
            newY = Math.min(0, newY + dragY * delta);
        }

        // configure velocity around max velocity.
        velX = clamp(newX, -maxVelX, maxVelX);
        velY = clamp(newY, -maxVelY, maxVelY);

        // update velocity based on position
        x = posX + velX * delta;
        y = posY + velY * delta;

        // reset flags here after the scene and sprites have been updated,
        // hopefully after the developer has done what they need with the
        // touching flags.
        resetTouchingFlags();

        lastX = posX;
        lastY = posY;
    }

    public function resetTouchingFlags () {
        touchingLeft = false;
        touchingRight = false;
        touchingUp = false;
        touchingDown = false;
    }
}
