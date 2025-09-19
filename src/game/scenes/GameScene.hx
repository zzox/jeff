package game.scenes;

import core.Game;
import core.gameobjects.BitmapText;
import core.gameobjects.GameObject;
import core.gameobjects.SImage;
import core.scene.Scene;
import core.system.Camera;
import core.util.Util;
import game.actors.Actor;
import game.actors.SpawnParticle;
import game.actors.World;
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
    var animTime:Int = 0;
    var delayTime:Int = 0;
    var seqMatches:Int = 0;
    var score:Int = 0;

    var decal:BitmapText;
    var drawTiles:DrawTiles;
    var scoreText:BitmapText;

    var world:World;

    var gameOver:Bool = false;

    var spawnParticles:Array<SpawnParticle> = [];

    override function create () {
        super.create();

        new UiText();

        camera.bgColor = 0xffff00ff;

        board = new Board(handleBoardEvent);
        world = new World();

        final bg = new SImage(0, 0, Assets.images.board_bg);
        bg.setScrollFactor(0, 0);
        entities.push(bg);
        entities.push(drawTiles = new DrawTiles(board));

        board.start();

        entities.push(scoreText = makeBitmapText(0, -4, ''));

        camera.startFollow(world.jeff, 60, 24);

        for (_ in 0...200) {
            final particle = new SpawnParticle();
            entities.push(particle);
            spawnParticles.push(particle);
        }
    }

    override function update (delta:Float) {
        // if we're in a delay, count down
        delayTime--;
        if (delayTime == 0) {
            drawTiles.matchItems.resize(0);
            if (board.island.length > 0) {
                animTime = 10;
            }
        }

        animTime--;
        if (animTime == 0) {
            board.animate();
            if (board.island.length > 0) {
                animTime += 5;
            }
        }

        if (delayTime <= 0 && animTime <= 0) {
            if (board.cItem.tiles.length == 0) {
                seqMatches = 0;
                board.start();
            }

            if (!gameOver) {
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
            }
        }

        world.update(delta, camera);
        super.update(delta);

        scoreText.setText(score + '');
        scoreText.x = 316 - scoreText.textWidth;

        // TODO: delete this
        if (Game.keys.justPressed(KeyCode.R)) {
            game.changeScene(new GameScene());
        }
    }

    override function render (g2:Graphics, clears:Bool) {
        g2.begin(clears, camera.bgColor);
        world.render(g2, camera);

        // from parent
        for (e in entities) if (e.visible) e.render(g2, camera);

        g2.end();
    }

    function handleBoardEvent (event:BoardEvent) {
        if (event.type == Match) {
            drawTiles.matchItems = event.items;
            delay(10);
            world.jeff.isJeffMoving = true;

            for (m in event.items) {
                final teammate = world.generateTeammate(getActorFromBlockType(m[0].item));

                score += Math.floor((5 + ((m.length - 3) * 5)) * (1 + seqMatches * 0.25));

                for (i in 0...m.length) {
                    for (_ in 0...16) {
                        genParticle(teammate, m[i]);
                    }
                }

                seqMatches++;
            }
        } else if (event.type == Island) {
            // eventText.setText('hit');
        } else if (event.type == Dead) {
            // eventText.setText('Game Over');
            gameOver = true;
        }
    }

    var particleIndex = -1;
    inline function genParticle (teammate:Actor, item:BlockItem) {
        final p = spawnParticles[(++particleIndex % spawnParticles.length)];

        final tempJeffSpeed = 120 * 0.1;

        // tileSize / 2 = 8
        p.spawn(
            item.x * tileSize + spawnX + 8,
            item.y * tileSize + spawnY + 8,
            teammate.x + 16 - camera.scrollX - tempJeffSpeed,
            teammate.y + 16 - camera.scrollY,
            actorData[teammate.type].particleColors[randomInt(actorData[teammate.type].particleColors.length)]
        );
    }

    function delay (time:Int) {
        delayTime = time;
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
