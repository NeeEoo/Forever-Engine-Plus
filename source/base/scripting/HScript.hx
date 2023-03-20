package base.scripting;

import flixel.FlxG;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.tweens.FlxTween;
import gameObjects.Boyfriend;
import gameObjects.Character;
import gameObjects.userInterface.HealthIcon;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.data.dependency.FNFSprite;
import openfl.Assets;

using StringTools;
/**
 * Any script using Haxe / HScript for handling.
 * @author Leather128, Sword352
 */
class HScript extends Script {
	/**
	 * `Map` to store all the default imports (variables, enums, classes, etc) for HScript files.
	 */
	public static var default_imports:haxe.ds.StringMap<Dynamic> = [
		// abstracts //
		'FlxColor' => HScriptClasses.FlxColor,
		'FlxInputState' => HScriptClasses.FlxInputState,
		'FlxAxes' => HScriptClasses.FlxAxes,

		// flixel.input.FlxInput.FlxInputStates //
		'JUST_RELEASED' => -1,
		'RELEASED' => 0,
		'PRESSED' => 1,
		'JUST_PRESSED' => 2,

		// flixel.util.FlxAxes //
		'X' => flixel.util.FlxAxes.X,
		'Y' => flixel.util.FlxAxes.Y,
		'XY' => flixel.util.FlxAxes.XY,

		// flixel.text.FlxTextBorderStyle //
		'NONE' => flixel.text.FlxText.FlxTextBorderStyle.NONE,
		'SHADOW' => flixel.text.FlxText.FlxTextBorderStyle.SHADOW,
		'OUTLINE' => flixel.text.FlxText.FlxTextBorderStyle.OUTLINE,
		'OUTLINE_FAST' => flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST,

		// flixel.tweens.FlxTween.FlxTweenType
		'PINGPONG' => FlxTweenType.PINGPONG,
		'BACKWARD' => FlxTweenType.BACKWARD,
		'LOOPING' => FlxTweenType.LOOPING,
		'ONESHOT' => FlxTweenType.ONESHOT,
		'PERSIST' => FlxTweenType.PERSIST,

		// imports //
		'FlxSprite' => flixel.FlxSprite,
		'FlxTween' => flixel.tweens.FlxTween,
		'FlxEase' => flixel.tweens.FlxEase,
		'FlxTrail' => FlxTrail,
		'FlxBackdrop' => FlxBackdrop,
		'FlxTimer' => flixel.util.FlxTimer,
		'FlxG' => flixel.FlxG,
		'FNFSprite' => FNFSprite,
		'Conductor' => meta.data.Conductor,
		'CustomShader' => base.shaders.CustomShader, // in case you wanna add shaders without manager
		'StringTools' => StringTools,
		'Json' => haxe.Json,
		'FlxMath' => flixel.math.FlxMath,
		@:access(flixel.math.FlxPoint.FlxBasePoint)
		'FlxPoint' => flixel.math.FlxPoint.FlxBasePoint,
		'FlxRect' => flixel.math.FlxRect,
		'FlxSound' => flixel.system.FlxSound,
		'FlxText' => flixel.text.FlxText,
		'FlxGroup' => flixel.group.FlxGroup,
		'FlxSpriteGroup' => flixel.group.FlxSpriteGroup,
		'ForeverTools' => ForeverTools,
		'ForeverAssets' => ForeverAssets,
		'UIStaticArrow' => UIStaticArrow,
		"Character" => Character,
		"Boyfriend" => Boyfriend,
		"HealthIcon" => HealthIcon,
		'Math' => Math,
		'Std' => Std,
		'Main' => Main,
		'CoolUtil' => meta.CoolUtil,
		'settings' => Init.trueSettings,
	    'Paths' => Paths,
		'platform' => #if windows "windows" #elseif macos "macos" #elseif linux "linux" #else "unknown" #end ,
		'isDesktop' => #if desktop true #else false #end,
	];

	// same docs as Script lmao
	public static var file_extensions:Array<String> = ['hxs', 'hx', 'hscript'];

	/**
	 * Parser that parses the HScript string.
	 */
	public var parser:hscript.Parser = new hscript.Parser();

	/**
	 * Interpreter to interpret the HScript and provide access
	 * to other variables / functions in the script.
	 */
	public var interp:hscript.Interp = new hscript.Interp();

	/**
	 * Raw script data.
	 */
	public var raw_script:String = '';

	/**
	 * Path to the hscript file that was loaded.
	 */
	public var hscript_path:String = '';

	/**
	 * Boolean to detect if the script is destroyed.
	 */
	public var script_destroyed:Bool = false;

	/**
	 * Creates and parses the HScript file at `path`.
	 * @param path Path to the HScript file to use.
	 */
	public function new(path:String, call_new:Bool = true) {
		script_destroyed = false; // just in case
        // Allows typing of variables ex: 'var three:Int = 3;', 'JSON Compatibility', and Haxe Metadata declarations in HScript
		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;
		interp.allowPublicVariables = interp.allowStaticVariables = true;

		// loop through extensions to make sure the path exists
		for (ext in file_extensions) {
			// path with ext
			if (Assets.exists(path) && path.endsWith('.${ext}')) {
				hscript_path = path;
				raw_script = Assets.getText(path);
				break;
			}
			// path without ext
			if (Assets.exists('${path}.${ext}')) {
				hscript_path = '${path}.${ext}';
				raw_script = Assets.getText('${path}.${ext}');
				break;
			}
		}

		// fallback
		if (raw_script == '') {
			trace('Could not find ${path} (no extension) as a valid HScript file, returning.');
			return;
		}

		var program:hscript.Expr = null;

		try {
			program = parser.parseString(raw_script);
		} catch (e) {
			trace('Parsing ${hscript_path} failed! Details: ${e.details()}');
		}

		set_defaults();

		try {
			interp.execute(program);
		} catch (e) {
			trace('Executing ${hscript_path} failed! Details: ${e.details()}');
		}

		if (call_new)
			call('new');

		// call this at the end cuz it calls the create function
		super(path);
	}

	/**
	 * Gets `item` and returns it.
	 * @param item Item to return.
	 * @return Value of `item`.
	 */
	public override function get(item:String):Dynamic {
		if(!script_destroyed) return interp.variables.get(item);
		else return null;
	}

	/**
	 * Returns whether or not `item` exists.
	 * @param item Item to check.
	 * @return Whether or not it exists.
	 */
	public override function exists(item:String):Bool {
		if(!script_destroyed) return interp.variables.exists(item);
		else return false;
	}

	/**
	 * Sets `item` to `value`.
	 * @param item Item to set.
	 * @param value Value to set `item` to.
	 */
	public override function set(item:String, value:Dynamic):Void {
		if(!script_destroyed) return interp.variables.set(item, value);
	}

	/**
	 * Calls `func` with arguments `args` and returns the result.
	 * @param func Function to call.
	 * @param args Arguments to call with.
	 * @return Result of the function.
	 */
	public override function call(func:String, ?args:Array<Dynamic>):Dynamic {
		if(!script_destroyed)
		{
			var real_func:Dynamic = get(func);

			// fallback shit
			try
			{
				if (real_func == null)
					return null;

				var return_value:Dynamic = Reflect.callMethod(null, real_func, args);
				return return_value;
			}
			catch (e)
			{
				trace('Error calling ${func} with ${args}! Details: ${e.details()}');
			}

			return null;
		}
		else return null;
	}

	/**
	 * Sets default variables in HScript.
	 */
	public override function set_defaults():Void {
		super.set_defaults();

		// basically sets all default imports lmao
		for (key in default_imports.keys()) {
			set(key, default_imports.get(key));
		}

		// functions and other stuff
		set('add', FlxG.state.add);
		// trace dumb >_<
		set('trace', function(value:Dynamic):Void {
			// complicated shit (i would use actually haxe trace but this faster i think + that one doesn't get file path correct)
			Sys.println('${hscript_path}:${interp.posInfos().lineNumber}: $value');
		});

		set("close", this.destroy);
		
		/*// load other scripts
		set('load', function(path:String, call_new:Bool = true):Script {
			var script:Script = Script.load(path);
			if (script == null)
				return null;

			if (funkin.scenes.Gameplay.instance != null)
				funkin.scenes.Gameplay.instance.scripts.push(script);
            if (call_new)
                script.call('new');
			script.call('create');

			return script;
		});*/
	}

	/**
	 * Adds `class_to_add` to the current set of variables.
	 * @param class_to_add Class to add.
	 */
	public function add_class(class_to_add:Dynamic, ?custom_name:String):Void {
		if(!script_destroyed)
		{
			if (custom_name == null)
			{
				var class_path_split:Array<String> = Type.getClassName(class_to_add).split('.');
				set(class_path_split[class_path_split.length - 1], class_to_add);
			}
			else
				set(custom_name, class_to_add);
		}
	}

	/**
	 * Adds all classes in the `classes` Array to the script.
	 * @param classes Array of classes to add.
	 */
	public function add_classes(classes:Array<Dynamic>):Void {
		if(!script_destroyed)
		{
			for (class_to_add in classes)
				add_class(class_to_add);
		}
	}

	/**
	 * Sets the current script object to `obj`.
	 * @param obj Object to set it to.
	 */
	public override function set_script_object(obj:Dynamic):Void {
		if(!script_destroyed)
		{
			var obj_class:Dynamic = Type.getClass(obj);

			for (key in Type.getClassFields(obj_class))
			{
				interp.staticVariables.set(key, Reflect.getProperty(obj_class, key));
			}

			interp.scriptObject = obj;
		}
	}

	/**
	 * Destroys this script.
	 */
	public override function destroy():Void {
		call('destroy');
		script_destroyed = true;
		
		// set values to null to try and manually clear them from memory :)
		parser = null;
		interp.variables.clear();
		interp = null;
		raw_script = null;

		super.destroy();
	}
}
