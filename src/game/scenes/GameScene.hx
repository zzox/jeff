package game.scenes;

import core.Game;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import game.board.Board;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final spawnX = 32;
final spawnY = 0;
final tileSize = 16;

final indexes:Map<BlockType, Int> = [
    Weight => 0,
    Pizza => 1,
    Outside => 2,
    Love => 3,
    Bomb => 4,
    None => -1
];

class GameScene extends Scene {
    var board:Board;

    var drawTiles:DrawTiles;
    var cItem:CItem;

    var dropSpeed:Int = 60;
    var dropTime:Int = 60;

    var animTime:Int = 10;

    override function create () {
        super.create();
        camera.bgColor = 0xff1b2632;

        board = new Board(onNewCItem);

        entities.push(new SImage(16, 16, Assets.images.board_bg));
        entities.push(drawTiles = new DrawTiles(board.grid, board.island));

        board.start();
    }

    override function update (delta:Float) {
        if (board.state == Play) {
            if (Game.keys.justPressed(KeyCode.Left)) {
                board.tryMoveLR(-1);
            }
            if (Game.keys.justPressed(KeyCode.Right)) {
                board.tryMoveLR(1);
            }
            if (Game.keys.justPressed(KeyCode.Up)) {
                board.tryRotate();
            }

            if (Game.keys.justPressed(KeyCode.Down)) {
                dropTime = 1;
            }
            dropSpeed = Game.keys.pressed(KeyCode.Down) ? 10 : 60;
            if (Game.keys.justReleased(KeyCode.Down)) {
                dropTime = 60;
            }

            dropTime--;
            if (dropTime == 0) {
                dropTime += dropSpeed;
                board.tryMoveDown();
            }
        } else {
            animTime--;
            if (animTime == 0) {
                board.animate();
                animTime += 5;
            }
        }

        if (dropTime < 0 || animTime < 0) {
            trace(dropTime, animTime);
            throw 'Bad times';
        }

        super.update(delta);

        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
        }
    }

    function onNewCItem (cItem:CItem) {
        drawTiles.cItem = cItem;
    }
}

class DrawTiles extends GameObject {
    var tiles:Grid;
    var island:Array<IslandItem>;
    public var cItem:CItem;

    public function new (tilesPtr:Grid, islandPtr:Array<IslandItem>) {
        this.tiles = tilesPtr;
        this.island = islandPtr;
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

        for (i in 0...island.length) {
            g2.drawSubImage(
                Assets.images.tiles,
                x + island[i].x * tileSize,
                y + island[i].y * tileSize,
                indexes.get(island[i].item) * 16, 0,
                16, 16
            );
        }

        if (cItem != null) {
            for (i in 0...cItem.tiles.length) {
                final tile = cItem.tiles[i];
                if (tile != None) {
                    final itemX = cItem.x + (i % itemSize);
                    final itemY = cItem.y + Math.floor(i / itemSize);
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
}
