--it was a pain to port week 7 shit to lua
--also some shit is haxe hardcoded because luajit throws exceptions when theres more than 5 arguments in function?????
--will probably move to hscript because luajit gets slowly on my nerves

isPicoOutro = false

--mr whiet i require methé
require "math"

print("lua works")

stageSpriteAnimationAddByPrefix("tankRolling", "idle", "BG tank w lighting instance 1", 24, true)
stageSpritePlay("tankRolling", "idle")

stageSpriteSetProperty("tankRolling", "x", -390)
stageSpriteSetProperty("tankRolling", "y", 500)

function onUpdate(elapsed)
    if isPicoOutro then
        setCamPosition("game", (getProperty("gf", "x") + getProperty("gf", "width") * 0.5) - 230, getProperty("gf", "y") + getProperty("gf", "height") * 0.5)
    end
end

function stepHit()
    if string.lower(swagSong.song) == "ugh" then
        if curStep == 60 or curStep == 444 or curStep == 524 or curStep == 828 then
            --addCameraZoom(0.2)
            characterPlayAnimation("dad", "ugh")
        end
    end

    if string.lower(swagSong.song) == "stress" then
        if curBeat >= 191 and isPicoOutro == false then
            setDadStrumLineAlpha(1)
            setCamZoom("game", 0.95)
        end
        if curStep == 736 then
            setDadStrumLineAlpha(0.1)
            setCamZoom("game", 1.3)
            characterPlayAnimation("dad", "prettyGood")
        end

        if curStep >= 1408 and curStep <= 1423 or curStep >= 1424 and curStep <= 1438 then
            if isPicoOutro == false then
                setGuiAlphaShit(0.0)
            end
            isPicoOutro = true
            characterPlayAnimation("gf", "picoShoot" .. math.random(1, 4))
        else
            if isPicoOutro == true then
                setGuiAlphaShit(1.0)
            end
            isPicoOutro = false
        end
    end

    if isPicoShooting() and math.random(0, 10) == 1 then
        callPlayStateFunction("spawnRunningTankman")
    end
end

function setGuiAlphaShit(alpha)
    setDadStrumLineAlpha(alpha)
    setBfStrumLineAlpha(alpha)
    setProperty("songTimeBar", "alpha", alpha)
    setProperty("timeLeftText", "alpha", alpha)
    setProperty("healthBarBG", "alpha", alpha)
    setProperty("healthBar", "alpha", alpha)
    setProperty("iconP1", "alpha", alpha)
    setProperty("iconP2", "alpha", alpha)
end

function setDadStrumLineAlpha(alpha)
    setStrumNoteAlpha("dad", 0, alpha)
    setStrumNoteAlpha("dad", 1, alpha)
    setStrumNoteAlpha("dad", 2, alpha)
    setStrumNoteAlpha("dad", 3, alpha)
end

function setBfStrumLineAlpha(alpha)
    setStrumNoteAlpha("bf", 0, alpha)
    setStrumNoteAlpha("bf", 1, alpha)
    setStrumNoteAlpha("bf", 2, alpha)
    setStrumNoteAlpha("bf", 3, alpha)
end

function beatHit()
    if math.random(0, 10000) == 420 then
        callPlayStateFunction("spawnRollingTankmen")
    end
end

function onNotePress(player, note)
    picoShoot(note)
end

function onNoteInStrumLine(note)
    picoShoot(note)
end

function picoShoot(note)
    if getProperty("gf", "curCharacter") == "pico-speaker" then
        if (curBeat >= 0 and curBeat <= 31 or curBeat >= 96 and curBeat <= 191 or curBeat >= 288 and curBeat <= 316) then
            characterPlayAnimation("gf", "picoShoot" .. (note[2] + 1))
            setProperty("gf", "idleAnim", "picoIdle" + math.random(1, 2))
        end
    end
end

function isPicoShooting()
    if string.lower(swagSong.song) == "stress" then
        return (curStep >= 1408 and curStep <= 1423 or curStep >= 1424 and curStep <= 1438) or (curBeat >= 0 and curBeat <= 31 or curBeat >= 96 and curBeat <= 191 or curBeat >= 288 and curBeat <= 316)
    end
    return false
end

--[[
function startRollin()
    if isRollin == false then
        isRollin = true
        stageSpriteSetProperty("tankRolling", "x", -390)
        stageSpriteSetProperty("tankRolling", "y", 500)
        tweenValue(0, 35, 15, "rollTweenFunction")
        doTankFunnyRollxdddd()
        stageSpriteTweenQuadMotion("tankRolling", -390, 500, 250, -5, 1520, 500 - 100, 15)
    end
end

function rollTweenFunction(f)
    stageSpriteSetProperty("tankRolling", "angle", f)
    if f == 35 then
        isRollin = false
    end
end
]]
