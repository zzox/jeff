package game.ui;

import core.gameobjects.BitmapText;
import core.util.BitmapFont;
import kha.Assets;

class UiText {
    public static var hopeGold:FntBitmapFont;
    public static var smallFont:ConstructBitmapFont;

    public function new () {
        hopeGold = makeFont();
        smallFont = makeSmallFont();
    }
}

function makeFont ():FntBitmapFont {
    return new FntBitmapFont(Assets.blobs.hope_gold_fnt.toString());
}

function makeSmallFont ():ConstructBitmapFont {
    return new ConstructBitmapFont(
        8, 8,
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,$:?!"\'+-=*%_() ',
        [
            [6, '$'],
            [5, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789?"+-=*%_()'],
            [3, ' '],
            [3, '.,;:!\''],
        ],
        -2
    );
}

function makeBitmapText (posX:Int, posY:Int, text:String = ''):BitmapText {
    return new BitmapText(posX, posY, Assets.images.hope_gold, UiText.hopeGold, text);
}

function makeSmallText (posX:Int, posY:Int, text:String = ''):BitmapText {
    return new BitmapText(posX, posY, Assets.images.cards_text, UiText.smallFont, text);
}
