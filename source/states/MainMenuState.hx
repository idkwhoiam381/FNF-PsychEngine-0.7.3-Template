package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class MainMenuState extends FlxState {
    var bg:FlxSprite;
    var bubbles:FlxTypedGroup<FlxSprite>;
    var logo:FlxSprite;
    var menuGroup:FlxTypedGroup<FlxSprite>;
    var buttons:Array<FlxSprite>;
    var buttonTexts:Array<FlxText>;
    var selected:Int = 0;
    var title:FlxText;
    var musicStarted:Bool = false;

    override public function create():Void {
        super.create();

		FlxG.mouse.visible = true;

        // --- Background ---
        bg = new FlxSprite().makeGraphic(1280, 720, FlxColor.fromHex(0xE6F6FF)); // fallback düz color
        bg.loadGraphic(Paths.image("wii/bg"), false, 1280, 720); // -- asset: images/wii/bg.png (1280x720)
        add(bg);

        // --- floating bubbles ---
        bubbles = new FlxTypedGroup<FlxSprite>();
        for (i in 0...12) {
            var b = new FlxSprite();
            b.loadGraphic(Paths.image("wii/bubble"), false, 128, 128); // asset: images/wii/bubble.png (ör: 128x128, alpha)
            b.x = FlxG.width * Math.random();
            b.y = FlxG.height + Math.random() * 400;
            var scale = 0.6 + Math.random() * 1.2;
            b.scale.set(scale, scale);
            b.alpha = 0.15 + Math.random() * 0.35;
            b.blend = "add";
            bubbles.add(b);
            add(b);
            // rise tween
            FlxTween.tween(b, { y: -200 - Math.random()*200 }, 6 + Math.random()*8, { type: FlxTween.PERSIST });
        }

        // --- Logo ---
        logo = new FlxSprite((FlxG.width / 2) - 220, 60);
        logo.loadGraphic(Paths.image("wii/logo"), false, 440, 140); // asset: images/wii/logo.png (e.g. 440x140)
        add(logo);

        // --- Title text (FNF style) ---
        title = new FlxText(0, 220, FlxG.width, "Wii Menu Funkin'");
        title.setFormat(null, 38, FlxColor.fromHex(0x004B99), "center", 0);
        add(title);

        // --- Menu buttons (sağ/sol seçilebilir) ---
        menuGroup = new FlxTypedGroup<FlxSprite>();
        buttons = [];
        buttonTexts = [];

        var labels = ["Play", "Options", "Credits", "Quit"];
        var startX = (FlxG.width / 2) - ((labels.length * 180) / 2); // her buton ~160 genişlik + margin
        for (i in 0...labels.length) {
            var bx = startX + i * 180;
            var by = 320;
            var btn = new FlxSprite(bx, by);
            btn.loadGraphic(Paths.image("wii/button"), false, 160, 80); // asset images/wii/button.png
            btn.frame = 0;
            btn.scale.set(1,1);
            add(btn);
            menuGroup.add(btn);
            buttons.push(btn);

            var txt = new FlxText(bx, by + 20, 160, labels[i]);
            txt.setFormat(null, 22, FlxColor.WHITE, "center");
            add(txt);
            buttonTexts.push(txt);

            // small pop tween loop
            FlxTween.float(btn, 0.04, 2 + i * 0.15, {ease: FlxTween.QUAD_IN_OUT, loop: true});
        }

        // initial highlight
        updateSelectionVisual();

        // --- Footer / hint ---
        var hint = new FlxText(0, FlxG.height - 48, FlxG.width, "Use ← → or A / D to move • Press ENTER / SPACE to select");
        hint.setFormat(null, 16, FlxColor.fromHex(0x0066CC), "center");
        add(hint);

        // play ambient menu music (optional)
        if (Paths.fileExists(Paths.music("freakyMenu"))) {
            FlxG.sound.playMusic(Paths.music("freakyMenu"));
            musicStarted = true;
        }

        // input repeat setup
        FlxG.keys.enabled = true;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // update bubble positions (if tween stops, respawn)
        for (b in bubbles.members) {
            if (b != null && b.y < -220) {
                b.y = FlxG.height + Math.random() * 300;
                b.x = Math.random() * FlxG.width;
                FlxTween.tween(b, { y: -220 - Math.random()*200 }, 6 + Math.random()*8, { type: FlxTween.PERSIST });
            }
        }

        // input: left / right
        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) {
            selected = (selected - 1 + buttons.length) % buttons.length;
            playNavSound();
            updateSelectionVisual();
        } else if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) {
            selected = (selected + 1) % buttons.length;
            playNavSound();
            updateSelectionVisual();
        }

        // press select
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || FlxG.keys.justPressed.X) {
            activateSelection();
        }

        // mouse hover + click (optional)
        for (i in 0...buttons.length) {
            var b = buttons[i];
            if (b.overlapsPoint(new FlxPoint(FlxG.mouse.x, FlxG.mouse.y))) {
                if (selected != i) {
                    selected = i;
                    playNavSound();
                    updateSelectionVisual();
                }
                if (FlxG.mouse.justReleasedLeft) {
                    activateSelection();
                }
            }
        }
    }

    function updateSelectionVisual():Void {
        for (i in 0...buttons.length) {
            var b = buttons[i];
            var t = buttonTexts[i];
            if (i == selected) {
                // highlight: slightly larger, glow, and move up
                FlxTween.tween(b, { scaleX: 1.08, scaleY: 1.08, y: b.y - 6 }, 0.12);
                t.setFormat(null, 24, FlxColor.WHITE, "center");
                // add quick pulse or glow
                FlxTween.tween(b, { alpha: 1.0 }, 0.08);
            } else {
                FlxTween.tween(b, { scaleX: 1.0, scaleY: 1.0, y: b.y + 0 }, 0.12);
                t.setFormat(null, 22, FlxColor.fromHex(0xEAF6FF), "center");
                FlxTween.tween(b, { alpha: 0.95 }, 0.08);
            }
        }

        // optional: bounce logo a bit on change
        FlxTween.tween(logo, { y: logo.y - 6 }, 0.08, { onComplete: function(t){ FlxTween.tween(logo, { y: logo.y + 6 }, 0.16); }});
    }

    function playNavSound():Void {
        if (Paths.fileExists(Paths.sound("scrollMenu"))) {
            FlxG.sound.play(Paths.sound("scrollMenu"));
        }
    }

    function playAcceptSound():Void {
        if (Paths.fileExists(Paths.sound("confirmMenu"))) {
            FlxG.sound.play(Paths.sound("confirmMenu"));
        }
    }

    function activateSelection():Void {
        playAcceptSound();
        switch (selected) {
            case 0:
                // Play -> go to song/select state (adjust to project)
                FlxG.switchState(new states.FreeplayState()); // veya MenuState'e göre değiştirin
            case 1:
                // Options
                FlxG.switchState(new options.OptionsState());
            case 2:
                FlxG.switchState(new states.CreditsState());
            case 3:
                // Quit
                FlxG.log("Quit selected");
                // For desktop:
                FlxG.pause(); // ya da Sys.exit()
        }
    }

    override public function destroy():Void {
        super.destroy();
        if (musicStarted) FlxG.sound.music.stop();
    }
}
