package game.board;

import core.Types;
import core.util.Util;

final boardWidth = 10;
final boardHeight = 15;

final itemSize = 2;

enum BlockType {
    Weight;
    Pizza;
    Outside;
    Love;
    Bomb;
    None;
}

final basicItems = [Weight, Pizza, Outside];

typedef Grid = Array<BlockType>;

typedef CItem = {
    var tiles:Grid; // 4 or 9 items
    var x:Int;
    var y:Int;
}

class Board {
    public var grid:Grid;
    public var cItem:CItem;

    var handleCItem:(cItem:CItem) -> Void;

    public function new (onCItem:(cItem:CItem) -> Void) {
        grid = [for (_ in 0...(boardWidth * boardHeight)) None];
        handleCItem = onCItem;
    }

    public function start () {
makeCItem();
    }

    public function tryMoveLR (moveX:Int) {
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.x += moveX;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (itemX < 0) {
                cItem.x = startX;
                trace('wall');
                break;
            }

            if (itemX >= boardWidth) {
                cItem.x = startX;
                trace('wall');
                break;
            }

            if (getItem(itemX, itemY) != None) {
                trace('brick');
                cItem.x = startX;
                break;
            }
        }
    }

    public function tryMoveDown () {
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.y++;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (getItem(itemX, itemY) != null && getItem(itemX, itemY) != None) {
                trace('brickdown');
                cItem.y = startY;
                stopItem();
                break;
            }

            if (itemY >= boardHeight) {
                trace('ground');
                cItem.y = startY;
                stopItem();
                break;
            }
        }
    }

    public function tryRotate () {
        final startX = cItem.x;
        final startY = cItem.y;
        rotate();

        var wallMoved = false;
        var hitGround = false;
        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (itemX < 0) {
                cItem.x++;
                wallMoved = true;
                break;
            }

            if (itemX >= boardWidth) {
                cItem.x--;
                wallMoved = true;
                break;
            }

            if (itemY >= boardHeight) {
                cItem.y--;
                hitGround = true;
                break;
            }
        }

        var brickMoved = false;
        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (getItem(itemX, itemY) == null) {
                throw 'shouldnt be here';
            }

            if (getItem(itemX, itemY) != None) {
                cItem.y--;
                brickMoved = true;
                break;
            }
        }

        if (hitGround && !brickMoved) {
            stopItem();
            return;
        }

        if (hitGround && brickMoved) {
            cItem.x = startX;
            cItem.y = startY;
            unRotate();
            trace('unrotating 1');
            return;
        }

        if (!hitGround && brickMoved) {
            cItem.x = startX;
            cItem.y = startY;
            unRotate();
            trace('unrotating 2');
            return;
        }
    }

    inline function rotate () {
        cItem.tiles = [cItem.tiles[2],cItem.tiles[0],cItem.tiles[3],cItem.tiles[1]];
    }

    inline function unRotate () {
        cItem.tiles = [cItem.tiles[1],cItem.tiles[3],cItem.tiles[0],cItem.tiles[2]];
    }

    // we've hit something. time to do the fun stuff
    function stopItem () {
        tilesLoop((type, x, y) -> {
            if (type != None) {
                setItem(x, y, type);
            }
        });

        // do matches
        var match = false;
        final consecutiveItems:Array<IntVec2> = [];
        var matchItem = null;
        for (y in 0...boardHeight) {
            consecutiveItems.resize(0);
            matchItem = null;

            for (x in 0...boardWidth) {
                if (matchItem == null && getItem(x, y) != None) {
                    matchItem = getItem(x, y);
                }

                if (getItem(x, y) == matchItem) {
                    consecutiveItems.push(new IntVec2(x, y));
                } else if (consecutiveItems.length >= 3) {
                    trace('match');
                    match = true;
                    doMatch(consecutiveItems);
                    break;
                } else if (getItem(x, y) != None) {
                    consecutiveItems.resize(0);
                    consecutiveItems.push(new IntVec2(x, y));
                    matchItem = getItem(x, y);
                } else {
                    consecutiveItems.resize(0);
                    matchItem = null;
                }
            }

            if (match) {
                break;
            }

            if (consecutiveItems.length >= 3) {
                trace('match edge');
                doMatch(consecutiveItems);
                break;
            }
        }

        // do matches
        var match = false;
        final consecutiveItems:Array<IntVec2> = [];
        var matchItem = null;
        for (x in 0...boardWidth) {
            consecutiveItems.resize(0);
            matchItem = null;

            for (y in 0...boardHeight) {
                if (matchItem == null && getItem(x, y) != None) {
                    matchItem = getItem(x, y);
                }

                if (getItem(x, y) == matchItem) {
                    consecutiveItems.push(new IntVec2(x, y));
                    trace(consecutiveItems.length);
                } else if (consecutiveItems.length >= 3) {
                    trace('match');
                    match = true;
                    doMatch(consecutiveItems);
                    break;
                } else if (getItem(x, y) != None) {
                    consecutiveItems.resize(0);
                    consecutiveItems.push(new IntVec2(x, y));
                    matchItem = getItem(x, y);
                } else {
                    consecutiveItems.resize(0);
                    matchItem = null;
                }
            }

            if (match) {
                break;
            }

            if (consecutiveItems.length >= 3) {
                doMatch(consecutiveItems);
                trace('match edge');
                break;
            }
        }

        makeCItem();
    }

    function makeCItem () {
        cItem = { tiles: [for (_ in 0...(itemSize * itemSize)) None], x: 3, y: 0 };

        cItem.tiles[2] = basicItems[randomInt(basicItems.length)];
        cItem.tiles[3] = basicItems[randomInt(basicItems.length)];

        handleCItem(cItem);
    }

    function doMatch (items:Array<IntVec2>) {
        trace(items);
        for (item in items) {
            setItem(item.x, item.y, None);
        }
    }

    inline function tilesLoop (cb) {
        for (i in 0...cItem.tiles.length) {
            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);
            cb(cItem.tiles[i], itemX, itemY);
        }
    }

    function setItem (x:Int, y:Int, item:BlockType) {
        grid[y * boardWidth + x] = item;
    }

    function getItem (x:Int, y:Int):Null<BlockType> {
        return grid[y * boardWidth + x];
    }
}
