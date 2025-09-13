package core.components;

import core.gameobjects.GameObject;

class Component {
    public var destroyed:Bool = true;
    public var active:Bool = true;

    public function new () {}

    public function update (time:Float) {
        throw 'Component::update not implemented';
    }
}
