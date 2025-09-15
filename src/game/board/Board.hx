package game.board;

import core.Types;
import core.util.Util;

final boardWidth = 7;
final boardHeight = 10;

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

enum BoardState {
    Play;
    Animate;
}

typedef IslandItem = {
    var item:BlockType;
    var x:Int;
    var y:Int;
}

enum BoardEventType {
    Match;
    Island;
}

typedef BoardEvent = {
    var type:BoardEventType;
    var items:Array<IntVec2>;
    var blockType:BlockType;
}

class Board {
    public var state:BoardState = Play;
    public var grid:Grid;
    public var cItem:CItem;
    public var island:Array<IslandItem> = [];

    var onBoardEvent:BoardEvent -> Void;

    public function new (onBoardEvent:BoardEvent -> Void) {
        grid = [for (_ in 0...(boardWidth * boardHeight)) None];
        cItem = { tiles: [], x: 2, y: 0 };
        this.onBoardEvent = onBoardEvent;
    }

    public function start () {
        makeCItem();
    }

    public function animate () {
        if (island.length == 0) throw 'No Island';
        if (state == Play) throw 'Bad State';

        var hit = false;
        for (i in 0...island.length) {
            // WARN: == not >=
            if (island[i].y + 1 == boardHeight || getItem(island[i].x, island[i].y + 1) != None) {
                hit = true;
            }
        }

        if (hit) {
            for (i in 0...island.length) {
                setItem(island[i].x, island[i].y, island[i].item);
            }
            island.resize(0);
            state = Play;
            makeCItem();
            return;
        }

        for (i in 0...island.length) {
            island[i].y++;
        }
    }

    public function tryMoveLR (moveX:Int) {
        if (state == Animate) throw 'should be Animating';

        final startX = cItem.x;
        final startY = cItem.y;

        cItem.x += moveX;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (itemX < 0) {
                cItem.x = startX;
                // trace('wall');
                break;
            }

            if (itemX >= boardWidth) {
                cItem.x = startX;
                // trace('wall');
                break;
            }

            if (getItem(itemX, itemY) != None) {
                // trace('brick');
                cItem.x = startX;
                break;
            }
        }
    }

    public function tryMoveDown () {
        if (state == Animate) throw 'should be Animating';
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.y++;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);

            if (getItem(itemX, itemY) != null && getItem(itemX, itemY) != None) {
                // trace('brickdown');
                cItem.y = startY;
                stopItem();
                break;
            }

            if (itemY >= boardHeight) {
                // trace('ground');
                cItem.y = startY;
                stopItem();
                break;
            }
        }
    }

    public function tryRotate () {
        if (state == Animate) throw 'should be Animating';
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
            // trace('unrotating 1');
            return;
        }

        if (!hitGround && brickMoved) {
            cItem.x = startX;
            cItem.y = startY;
            unRotate();
            // trace('unrotating 2');
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
        forEachCItem((type, x, y) -> {
            if (type != None) {
                setItem(x, y, type);
            }
        });

        // do matches
        // WARN: logic is mirrored on other axis, below
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
                    // trace('match');
                    doMatch(consecutiveItems, matchItem);
                    match = true;
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
                // trace('match edge');
                doMatch(consecutiveItems, matchItem);
                match = true;
                break;
            }
        }

        // do matches (y axis)
        if (!match) {
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
                    } else if (consecutiveItems.length >= 3) {
                        // trace('match');
                        doMatch(consecutiveItems, matchItem);
                        match = true;
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
                    doMatch(consecutiveItems, matchItem);
                    match = true;
                    // trace('match edge');
                    break;
                }
            }
        }

        if (match) makeIslands();

        if (island.length > 0) {
            state = Animate;
            removeCItem();
        } else {
            makeCItem();
        }
    }

    // get the 4 closest neighbors if they are real items
    final poss = [new IntVec2(-1, 0), new IntVec2(1, 0), new IntVec2(0, -1), new IntVec2(0, 1)];
    function getNeighbors (x:Int, y:Int):Array<IntVec2> {
        final items = [];
        for (i in 0...poss.length) {
            final item = getItem(x + poss[i].x, y + poss[i].y);
            if (item != null && item != None) {
                items.push(new IntVec2(x + poss[i].x, y + poss[i].y));
            }
        }
        return items;
    }

    var groundItems:Array<Bool> = [for (_ in 0...(boardWidth * boardHeight)) false];
    function makeIslands () {
        // find all that are on ground, group those
        for (i in 0...groundItems.length) groundItems[i] = false;

        for (x in 0...boardWidth) {
            final item = getItem(x, boardHeight - 1);

            if (item != None && !bArrayContains(groundItems, x, boardHeight - 1)) {
                groundItems[(boardHeight - 1) * boardWidth + x] = true;
                var toCheck = getNeighbors(x, boardHeight - 1);

                while (toCheck.length > 0) {
                    final check = toCheck.pop();
                    if (!bArrayContains(groundItems, check.x, check.y)) {
                        groundItems[check.y * boardWidth + check.x] = true;
                        toCheck = toCheck.concat(getNeighbors(check.x, check.y));
                    }
                }
            }
        }

        // trace(groundItems);

        // iterate through all items, find ones that aren't grouped
        // when adding to island, remove from the board
        // island.resize(0);

        for (i in 0...grid.length) {
            final item = getItem(i % boardWidth, Math.floor(i / boardWidth));
            if (item != None && !groundItems[i]) {
                island.push({ item: item, x: i % boardWidth,y: Math.floor(i / boardWidth) });
                setItem(i % boardWidth, Math.floor(i / boardWidth), None);
            }
        }

        // drop each like we drop by y
        // ALL need to move downwards each step, we don't exit early

        // when one island hits, we erase all!
    }

    function makeCItem () {
        cItem.x = 2;
        cItem.y = 0;
        cItem.tiles = [for (_ in 0...(itemSize * itemSize)) None];

        cItem.tiles[0] = basicItems[randomInt(basicItems.length)];
        cItem.tiles[1] = basicItems[randomInt(basicItems.length)];
    }

    function removeCItem () {
        cItem.tiles.resize(0);
    }

    function doMatch (items:Array<IntVec2>, type:BlockType) {
        // trace(items);
        for (item in items) {
            setItem(item.x, item.y, None);
        }

        onBoardEvent({ type: Match, items: items, blockType: type });
    }

    inline function forEachCItem (cb) {
        for (i in 0...cItem.tiles.length) {
            final itemX = cItem.x + (i % itemSize);
            final itemY = cItem.y + Math.floor(i / itemSize);
            cb(cItem.tiles[i], itemX, itemY);
        }
    }

    function bArrayContains (arr:Array<Bool>, x:Int, y:Int):Bool {
        return arr[y * boardWidth + x];
    }

    // function arrayContains (arr:Array<IntVec2>, x:Int, y:Int):Bool {
    //     for (i in 0...arr.length) {
    //         if (arr[i].x == x && arr[i].y == y) return true;
    //     }

    //     return false;
    // }

    function setItem (x:Int, y:Int, item:BlockType) {
        grid[y * boardWidth + x] = item;
    }

    function getItem (x:Int, y:Int):Null<BlockType> {
        return grid[y * boardWidth + x];
    }
}
