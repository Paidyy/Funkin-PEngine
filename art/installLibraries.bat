@echo off

echo | set /p=[97m

haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hscript
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib install openfl-webm
haxelib git yaml https://github.com/Paidyy/haxe-yaml.git
haxelib install linc_luajit
haxelib install udprotean
haxelib git linc_clipboard https://github.com/josuigoa/linc_clipboard.git
haxelib install markdown

echo.
echo [37m------------------------------------
echo.
echo [92mSuccesfully Installed Libraries!
echo.
echo [37m------------------------------------
echo [0m
PAUSE