package game.scenes;

import core.Game;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final boardWidth = 10;
final boardHeight = 15;

final spawnX = 32;
final spawnY = 0;
final tileSize = 16;

enum BlockType {
    Weight;
    None;
}

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
            if (tiles[i] != None) {
                g2.drawImage(
                    Assets.images.tiles,
                    x + (i % boardWidth) * tileSize,
                    y + Math.floor(i / boardWidth) * tileSize
                );
            }
        }

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] != None) {
                // WARN: this assumes 3x3 cItems
                var itemX = cItem.x + (i % 3);
                var itemY = cItem.y + Math.floor(i / 3);
                g2.drawImage(
                    Assets.images.tiles,
                    x + (itemX % boardWidth) * tileSize,
                    y + itemY * tileSize
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

        board = [for (_ in 0...140) None];

        entities.push(new SImage(16, 16, Assets.images.board_bg));
        entities.push(drawTiles = new DrawTiles(board));
        makeCItem();
    }

    override function update (delta:Float) {
        if (Game.keys.justPressed(KeyCode.Left)) {
            // camera.bgColor = 0xffffff00;
            // cItem.x--;
            tryMove(-1, 0);
        }
        if (Game.keys.justPressed(KeyCode.Right)) {
            // camera.bgColor = 0xffffffff;
            // cItem.x++;
            tryMove(1, 0);
        }
        if (Game.keys.justPressed(KeyCode.Up)) {
            // camera.bgColor = 0xff00ffff;
        }

        if (Game.keys.justPressed(KeyCode.Down)) {
            dropTime = 0.0;
        }
        dropSpeed = Game.keys.pressed(KeyCode.Down) ? 0.25 : 1.0;
        if (Game.keys.justReleased(KeyCode.Down)) {
            dropTime = 1.0;
        }

        dropTime -= delta;
        if (dropTime < 0) {
            dropTime += dropSpeed;
            tryMove(0, 1);
            checkCollisions();
        }

        super.update(delta);

        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
        }
    }

    function tryMove (moveX:Int, moveY:Int) {
        final startX = cItem.x;
        final startY = cItem.y;

        cItem.x += moveX;
        cItem.y += moveY;

        for (i in 0...cItem.tiles.length) {
            if (cItem.tiles[i] == None) continue;

            // WARN: this assumes 3x3 cItems
            var itemX = cItem.x + (i % 3);
            var itemY = cItem.y + Math.floor(i / 3);

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

            if (itemY >= boardHeight) {
                trace('ground');
                cItem.y = startY;
                stopItem();
                break;
            }
        }
    }

    function stopItem () {
        tilesLoop((type, x, y) -> {
            if (type != None) {
                setItem(x, y, type);
            }
        });
        makeCItem();
    }

    function makeCItem () {
        cItem = { tiles: [for (_ in 0...9) None], x: 3, y: 0 };

        // TEMP:
        cItem.tiles[3] = Weight;
        cItem.tiles[4] = Weight;
        cItem.tiles[5] = Weight;

        drawTiles.cItem = cItem;
    }

    function checkCollisions () {}

    inline function tilesLoop (cb) {
        for (i in 0...cItem.tiles.length) {
            // WARN: this assumes 3x3 cItems
            var itemX = cItem.x + (i % 3);
            var itemY = cItem.y + Math.floor(i / 3);
            cb(cItem.tiles[i], itemX, itemY);
        }
    }

    function setItem (x:Int, y:Int, item:BlockType) {
        board[y * boardWidth + x] = item;
    }

    function getItem (x:Int, y:Int):BlockType {
        return board[y * boardWidth + x];
    }
}
