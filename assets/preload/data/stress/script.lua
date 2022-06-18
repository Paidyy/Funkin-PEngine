function beatHit()
    setField('disableEvilCamZoom', false)
    if (curBeat >= 224 and curBeat <= 255) or (curBeat >= 320 and curBeat <= 351) then
        setField('disableEvilCamZoom', true)
        setProperty('camHUD', 'zoom', getProperty('camHUD', 'zoom') + 0.06)
        setProperty('camGame', 'zoom', getProperty('camGame', 'zoom') + 0.15)
    end
end
