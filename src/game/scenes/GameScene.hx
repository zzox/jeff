package game.scenes;

import core.Game;
import core.Types.IntVec2;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import core.util.Util;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final boardWidth = 10;
final boardHeight = 15;

final spawnX = 32;
final spawnY = 0;
final tileSize = 16;

final itemSize = 2;

enum BlockType {
    Weight;
    Pizza;
    Outside;
    Love;
    Bomb;
    None;
}

final indexes:Map<BlockType, Int> = [
    Weight => 0,
    Pizza => 1,
    Outside => 2,
    Love => 3,
    Bomb => 4,
    None => -1
];

final basicItems = [Weight, Pizza, Outside];

typedef Board = Array<BlockType>;

class DrawTiles extends GameObject {
    var tiles:Board;
    public var cItem:CItem;

    public function new (tilesPtr:Board) {
        this.tiles = tilesPtr;
        this.x = spawnX;
        this.y = spawnY;
    }

    override function update (delta:Float) {}

    override function render (g2:Graphics, cam:Camera) {
        for (i in 0...tiles.length) {
            final tile = tiles[i];
            if (tile != None) {
                g2.drawSubImage(
                    Assets.images.tiles,
                    x + (i % boardWidth) * tileSize,
                    y + Math.floor(i / boardWidth) * tileSize,
                    indexes.get(tile) * 16, 0,
                    16, 16
                );
            }
        }

        for (i in 0...cItem.tiles.length) {
            final tile = cItem.tiles[i];
            if (tile != None) {
                var itemX = cItem.x + (i % itemSize);
                var itemY = cItem.y + Math.floor(i / itemSize);
                g2.drawSubImage(
                    Assets.images.tiles,
                    x + (itemX % boardWidth) * tileSize,
                    y + itemY * tileSize,
                    indexes.get(tile) * 16, 0,
                    16, 16
                );
            }
        }
    }
}

enum ItemDir {
    Flat;
    Up;
}

typedef CItem = {
    var tiles:Board; // 9 items
    var x:Int;
    var y:Int;
};

class GameScene extends Scene {
    var board:Board;

    var drawTiles:DrawTiles;
    var cItem:CItem;

    var dropSpeed:Float = 1.0;
    var dropTime:Float = 1.0;

    override function create () {
        super.create();
        camera.bgColor = 0xff1b2632;

        board = [for (_ in 0...(boardWidth * boardHeight)) None];

        entities.push(new SImage(16, 16, Assets.images.board_bg));
        entities.push(drawTiles = new DrawTiles(board));
        makeCItem();
    }

    override function update (delta:Float) {
        if (Game.keys.justPressed(KeyCode.Left)) {
            // camera.bgColor = 0xffffff00;
            // cItem.x--;
            tryMoveLR(-1);
        }
        if (Game.keys.justPressed(KeyCode.Right)) {
            // camera.bgColor = 0xffffffff;
            // cItem.x++;
            tryMoveLR(1);
        }
        if (Game.keys.justPressed(KeyCode.Up)) {
            // camera.bgColor = 0xff00ffff;
        }

        if (Game.keys.justPressed(KeyCode.Down)) {
            dropTime = 0.0;
        }
        dropSpeed = Game.keys.pressed(KeyCode.Down) ? 0.15 : 1.0;
        if (Game.keys.justReleased(KeyCode.Down)) {
            dropTime = 1.0;
        }

        dropTime -= delta;
        if (dropTime < 0) {
            dropTime += dropSpeed;
            tryMoveDown();
            checkCollisions();
        }

        super.update(delta);

        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
        }
    }

    function tryMoveLR (moveX:Int) {
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.x += moveX;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            // WARN: this assumes 3x3 cItems
            var itemX = cItem.x + (i % 2);
            var itemY = cItem.y + Math.floor(i / 2);

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

    function tryMoveDown () {
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.y++;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            var itemX = cItem.x + (i % itemSize);
            var itemY = cItem.y + Math.floor(i / itemSize);

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
                    trace(consecutiveItems.length);
                } else if (consecutiveItems.length >= 3) {
                    trace('do something', matchItem, consecutiveItems);
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
                    trace('do something', matchItem, consecutiveItems);
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
                break;
            }
        }

        makeCItem();
    }

    function makeCItem () {
        cItem = { tiles: [for (_ in 0...9) None], x: 3, y: 0 };

        cItem.tiles[2] = basicItems[randomInt(basicItems.length)];
        cItem.tiles[3] = basicItems[randomInt(basicItems.length)];

        drawTiles.cItem = cItem;
    }

    function doMatch (items:Array<IntVec2>) {
        trace(items);
        for (item in items) {
            setItem(item.x, item.y, None);
        }
    }

    function checkCollisions () {}

    inline function tilesLoop (cb) {
        for (i in 0...cItem.tiles.length) {
            var itemX = cItem.x + (i % itemSize);
            var itemY = cItem.y + Math.floor(i / itemSize);
            cb(cItem.tiles[i], itemX, itemY);
        }
    }

    function setItem (x:Int, y:Int, item:BlockType) {
        board[y * boardWidth + x] = item;
    }

    function getItem (x:Int, y:Int):Null<BlockType> {
        return board[y * boardWidth + x];
    }
}
