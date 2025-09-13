package game.scenes;

import core.Game;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final spawnX = 32;
final spawnY = 16;
final boardWidth = 10;
final tileSize = 16;

enum BlockType {
    Weight;
    None;
}

typedef Board = Array<BlockType>;

class DrawTiles extends GameObject {
    var tiles:Board;
    var cItem:CItem;

    public function new (tilesPtr:Board, cItemPtr:CItem) {
        this.tiles = tilesPtr;
        this.cItem = cItemPtr;
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
    var tiles:Board;
    var tilesImage:DrawTiles;
    var cItem:CItem;

    var dropSpeed:Float = 1.0;
    var dropTime:Float = 0.0;

    override function create () {
        super.create();
        camera.bgColor = 0xff1b2632;

        tiles = [for (_ in 0...140) None];
        cItem = { tiles: [for (_ in 0...9) None], x: 3, y: 0 };

        // TEMP:
        cItem.tiles[3] = Weight;
        cItem.tiles[4] = Weight;
        cItem.tiles[5] = Weight;

        entities.push(new SImage(16, 16, Assets.images.board_bg));
        entities.push(new DrawTiles(tiles, cItem));
    }

    override function update (delta:Float) {
        if (Game.keys.justPressed(KeyCode.Left)) {
            // camera.bgColor = 0xffffff00;
            cItem.x--;
        }
        if (Game.keys.justPressed(KeyCode.Right)) {
            // camera.bgColor = 0xffffffff;
            cItem.x++;
        }
        if (Game.keys.justPressed(KeyCode.Up)) {
            // camera.bgColor = 0xff00ffff;
        }
        if (Game.keys.justPressed(KeyCode.Down)) {
            // camera.bgColor = 0xff0000ff;
        }

        dropTime -= delta;
        if (dropTime < 0) {
            dropTime += dropSpeed;
            cItem.y++;

            trace(cItem.y);
        }

        super.update(delta);
    }
}
