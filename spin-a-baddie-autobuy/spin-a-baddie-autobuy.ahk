#Requires AutoHotkey v2.0
SendMode('Event')
SetTitleMatchMode(2)
CoordMode('Pixel', 'Client')
CoordMode('Mouse', 'Client')

global running := false
global scrollDownCount := 0
global softScrollLimit := 110
global buyCount := 0

robloxWindow := 'ahk_exe RobloxPlayerBeta.exe'

stockClickOffsetY := 20
buyDismissOffsetY := -100

stockIndicator := {
    name: 'stock',
    coords: [807, 384, 933, 629],
    color: 0x59FF59
}

buyButton := {
    name: 'buy',
    coords: [787, 381, 945, 766],
    color: 0x1DD52A
}

endOfListIndicator := {
    coords: [801, 381, 1193, 654]
}

#HotIf WinActive(robloxWindow)

F1:: {
    global running
    if (running) {
        running := false
        ShowStatus('Paused')
        return
    }

    running := true
    ShowStatus('Searching...', buyCount)

    Loop {
        if (!running)
            break

        if (AreaSearch(stockIndicator)) {
            continue
        }

        if (!running)
            break

        AreaSearch(buyButton)
    }

    ShowStatus('Stopped')
}

F12:: ExitApp()

#HotIf

AreaSearch(target) {
    global scrollDownCount, running, buyCount, stockClickOffsetY, buyDismissOffsetY
    shouldScrollBackUp := false
    searchScrollCount := 0

    while (running) {
        found := false
        try {
            found := PixelSearch(&targetX, &targetY, target.coords[1], target.coords[2], target.coords[3], target.coords[4], target.color, 5)
        }
        if (found)
            break

        if (IsEndOfList()) {
            if (target.name == 'stock') {
                if (shouldScrollBackUp) {
                    ShowStatus('Scrolling back...')
                    ScrollBackUp()
                    ShowStatus('Searching...', buyCount)
                    return true
                }
            }

            shouldScrollBackUp := true
        }

        Sleep(100)
        Send('{WheelDown}')
        scrollDownCount++
        searchScrollCount++
        Sleep(100)
        RandomJump()

        if (searchScrollCount >= 5 AND target.name == 'buy') {
            if (shouldScrollBackUp) {
                ShowStatus('Scrolling back...')
                ScrollBackUp()
                ShowStatus('Searching...', buyCount)
            }

            return false
        }
    }

    if (!running)
        return false

    ShowStatus('Buying...')
    HumanClick(targetX, targetY + stockClickOffsetY)

    if (target.name == 'buy') {
        HumanClick(targetX, targetY + buyDismissOffsetY)
        buyCount++

        if (shouldScrollBackUp) {
            ShowStatus('Scrolling back...')
            ScrollBackUp()
        }

        ShowStatus('Searching...', buyCount)
    }

    return false
}

HumanClick(x, y) {
    Sleep(Random(120, 280))
    Click(x, y)
    Sleep(Random(120, 280))
}

IsEndOfList() {
    global scrollDownCount, softScrollLimit
    if (scrollDownCount >= softScrollLimit) {
        return true
    }

    coords := endOfListIndicator.coords
    try {
        return ImageSearch(&x, &y, coords[1], coords[2], coords[3], coords[4], '*25 last-dice.png')
    } catch {
        return false
    }
}

ScrollBackUp() {
    global scrollDownCount, softScrollLimit
    softScrollLimit := scrollDownCount
    remaining := scrollDownCount

    while (remaining > 0) {
        batch := Min(5, remaining)
        Loop batch {
            Send('{WheelUp}')
        }
        remaining -= batch
        Sleep(50)
    }

    scrollDownCount := 0
    Sleep(500)
}

RandomJump() {
    if (Random(1, 100) == 1) {
        Send('{Space}')
    }
}

ShowStatus(text, count := 0) {
    static hud := false
    static label := false
    static dot := false
    static hideTimer := false

    colors := Map(
        'Searching...', { bg: '1a1a2e', fg: '00d4ff', dot: '00d4ff' },
        'Buying...',     { bg: '1a2e1a', fg: '59ff59', dot: '59ff59' },
        'Scrolling back...', { bg: '2e2a1a', fg: 'ffaa00', dot: 'ffaa00' },
        'Paused',        { bg: '2e1a1a', fg: 'ff5555', dot: 'ff5555' },
        'Stopped',       { bg: '1a1a1a', fg: '888888', dot: '888888' }
    )

    theme := colors.Has(text) ? colors[text] : { bg: '1a1a1a', fg: 'cccccc', dot: 'cccccc' }
    displayText := (count > 0) ? text ' [' count ']' : text

    if (!hud) {
        hud := Gui('+AlwaysOnTop -Caption +ToolWindow +E0x20')
        hud.MarginX := 12
        hud.MarginY := 10
        hud.BackColor := theme.bg
        dot := hud.AddText('x12 y10 w12 h24 vDot', Chr(0x2022))
        dot.SetFont('s10 c' theme.dot, 'Segoe UI')
        label := hud.AddText('x26 y8 w150 h24 vLabel', displayText)
        label.SetFont('s10 c' theme.fg, 'Segoe UI Semibold')
        WinSetTransparent(230, hud)
    } else {
        hud.BackColor := theme.bg
        dot.SetFont('s10 c' theme.dot)
        label.SetFont('s10 c' theme.fg)
        label.Text := displayText
        dot.Text := Chr(0x2022)
    }

    hud.Show('x16 y16 NoActivate AutoSize')

    if (hideTimer)
        SetTimer(hideTimer, 0)

    if (text == 'Stopped' || text == 'Paused') {
        hideTimer := () => hud.Hide()
        SetTimer(hideTimer, -4000)
    } else {
        hideTimer := false
    }
}
