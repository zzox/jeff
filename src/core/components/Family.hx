package core.components;

import core.components.Component;

class Family<T:Component> {
    public var items:Array<T> = [];
    var index:Int = -1;

    var allocate:(num:Int) -> Array<T>;

    public function new (allocate:(num:Int) -> Array<T>, ?initialNum:Int) {
        this.allocate = allocate;

        if (initialNum != null) {
            allocateAndAdd(initialNum);
        }
    }

    public function update (delta:Float) {
        for (i in items) i.update(delta);
    }

    // careful using this, could get one being used
    public function getNext ():T {
        return items[++index % items.length];
    }

    public function getOrCreate ():T {
        var i = items.length;
        while (--i > 0) {
            if (!items[i].active) {
                items[i].active = true;
                return items[i];
            }
        }

        // allocate and return the last (new) one
        allocateAndAdd(1);
        return items[items.length - 1];
    }

    inline function allocateAndAdd (num:Int) {
        items = items.concat(allocate(num));
    }
}
