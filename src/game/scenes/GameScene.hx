package game.scenes;

import core.Game;
import core.Types.IntVec2;
import core.gameobjects.BitmapText;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import game.board.Board;
import game.ui.UiText;
import kha.Assets;
import kha.graphics2.Graphics;
import kha.input.KeyCode;

final spawnX = 8;
final spawnY = 8;
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

    var dropSpeed:Int = 60;
    var dropTime:Int = 60;
    var animTime:Int = 10;

    var drawTiles:DrawTiles;

    var delaying:Bool = false;
    var delayFrames:Int = 0;
    var eventText:BitmapText;

    override function create () {
        super.create();

        new UiText();

        camera.bgColor = 0xff1b2632;

        board = new Board(handleBoardEvent);

        entities.push(new SImage(-8, 8, Assets.images.board_bg));
        entities.push(drawTiles = new DrawTiles(board));

        board.start();

        entities.push(eventText = makeBitmapText(0, 0, ''));
    }

    override function update (delta:Float) {
        if (delaying) {
            delayFrames--;
            if (delayFrames == 0) {
                drawTiles.matchItems.resize(0);
                delaying = false;
                board.start();
            }
        }

        // ew, consider using curlies for this
        if (!delaying)
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

        // TODO: delete this
        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
        }
    }

    function handleBoardEvent (event:BoardEvent) {
        if (event.type == Match) {
            trace(event.items);
            eventText.setText('match');
            drawTiles.matchItems = event.items;
            delay(10);
        } else {
        }
    }

    function delay (time:Int) {
        delayFrames = time;
        delaying = true;
    }
}

class DrawTiles extends GameObject {
    var board:Board;
    public var matchItems:Array<Array<BlockItem>> = [];

    public function new (boardPtr:Board) {
        this.board = boardPtr;
        this.x = spawnX;
        this.y = spawnY;
    }

    override function update (delta:Float) {}

    override function render (g2:Graphics, cam:Camera) {
        for (i in 0...board.grid.length) {
            final tile = board.grid[i];
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

        for (i in 0...board.island.length) {
            g2.drawSubImage(
                Assets.images.tiles,
                x + board.island[i].x * tileSize,
                y + board.island[i].y * tileSize,
                indexes.get(board.island[i].item) * 16, 0,
                16, 16
            );
        }

        for (i in 0...board.cItem.tiles.length) {
            final tile = board.cItem.tiles[i];
            if (tile != None) {
                final itemX = board.cItem.x + (i % itemSize);
                final itemY = board.cItem.y + Math.floor(i / itemSize);

                g2.drawSubImage(
                    Assets.images.tiles,
                    x + (itemX % boardWidth) * tileSize,
                    y + itemY * tileSize,
                    indexes.get(tile) * 16, 0,
                    16, 16
                );
            }
        }

        for (i in 0...matchItems.length) {
            for (j in 0...matchItems[i].length) {
                g2.drawSubImage(
                    Assets.images.tiles,
                    x + matchItems[i][j].x * tileSize,
                    y + matchItems[i][j].y * tileSize,
                    indexes.get(matchItems[i][j].item) * 16, 16,
                    16, 16
                );
            }
        }
    }
}
