package core.util;

function clamp (value:Float, min:Float, max:Float) {
    return Math.max(Math.min(value, max), min);
}

function lerp (target:Float, current:Float, percent:Float):Float {
    return current + (target - current) * percent;
}

function randomInt (ceil:Int) {
    return Math.floor(Math.random() * ceil);
}
