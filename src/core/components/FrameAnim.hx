package core.components;

import core.gameobjects.Sprite;

typedef AnimItem = {
    var name:String;
    var vals:Array<Int>;
    var frameTime:Int;
    var repeats:Bool;
}

class FrameAnim extends Component {
    public var sprite:Sprite;

    var _animations:Map<String, AnimItem> = new Map();

    var animTime:Float;
    var currentAnim:AnimItem;

    public function add (name:String, vals:Array<Int>, frameTime:Int = 1, repeats:Bool = true) {
        _animations[name] = {
            name: name,
            vals: vals,
            frameTime: frameTime,
            repeats: repeats
        };
    }

    // Play animation by name.  Won't restart same anim unless forced.
    public function play (name:String, forceRestart:Bool = false) {
        // isPaused = false;
        // NOTE: `|| completed` isn't adequately tested
        if (forceRestart /*|| completed*/ || currentAnim == null || name != currentAnim.name) {
            animTime = 0;
            currentAnim = _animations.get(name);
            // completed = false;
            // HACK: without this a previous anim may play before the sprite is updated.
            // spriteRef.tileIndex = currentAnim.vals[0];
        }
    }

    override function update (delta:Float) {
        // unnecessary null-check? compilation macro in future?
        if (currentAnim == null) {
            return;
        }

        animTime++;

        final frameAnimTime = Math.floor(animTime / currentAnim.frameTime);

        if (!currentAnim.repeats && frameAnimTime >= currentAnim.vals.length) {
            sprite.tileIndex = currentAnim.vals[currentAnim.vals.length - 1];
            // if (!completed) {
            //     onComplete(currentAnim.name);
            //     completed = true;
            // }
        } else {
            sprite.tileIndex = currentAnim.vals[frameAnimTime % currentAnim.vals.length];
        }
    }
}
