import XMonad ((<+>), (=?), (-->), (|||), (.|.))
import qualified XMonad as XM


import qualified XMonad.Actions.PhysicalScreens as PS
import qualified XMonad.Actions.Warp as Warp


import qualified XMonad.Hooks.DynamicBars as DBars
import qualified XMonad.Hooks.DynamicLog as DLog
import qualified XMonad.Hooks.ManageDocks as Docks -- Unmanage windows like trayer and xmobar
import qualified XMonad.Hooks.UrgencyHook as Urg
import qualified XMonad.Hooks.ManageHelpers as Help 
import qualified XMonad.Hooks.EwmhDesktops as Ewmh -- wmctrl for matlab/vim

import qualified XMonad.Layout.Renamed as Rename
import qualified XMonad.Layout.ResizableTile as Resize -- Resize tall layouts vertically
import qualified XMonad.Layout.NoBorders as Borders -- smartBorders
import qualified XMonad.Layout.SimplestFloat as Float
import qualified XMonad.Layout.PerWorkspace as PerWS

import qualified XMonad.Util.EZConfig as EZ
import qualified XMonad.Util.Run as Run


import qualified XMonad.StackSet as W


import qualified Data.Time.LocalTime as LT
import MyColors

import XMonad.Hooks.SetWMName



main = do
    XM.spawn trayerCmd
    XM.xmonad $ Urg.withUrgencyHook Urg.NoUrgencyHook
              $ Ewmh.ewmh 
              $ XM.defaultConfig
        { XM.logHook         = DBars.multiPP (myLogPP) (myLogPP)

        , XM.startupHook     = do
                                 setWMName "LG3D"
                                 DBars.dynStatusBarStartup barCreator barDestroyer
                                 XM.spawn "~/.xmonad/startup-hook.sh"

        , XM.handleEventHook =     DBars.dynStatusBarEventHook barCreator barDestroyer -- new xmobars when turning monitors on/off
                               <+> Docks.docksEventHook -- make new bars visible

        -- Unmanages docks like trayer, otherwise trayer would also be a tiled window
        , XM.manageHook      =     Docks.manageDocks 
                               <+> myManageHook

        -- avoidStruts tells layouts to avoid struts (xmobar)
        -- smartBorders remove borders on any layout with just one window visible
        -- (i.e. any with just one window, and Full)
        , XM.layoutHook      = Docks.avoidStruts ( Borders.smartBorders (
                                   PerWS.onWorkspaces ["9flt"] (Rename.renamed [Rename.Replace "Flt"] Float.simplestFloat) 
                                 $ myLayouts
                               ))

        -- Basics
        , XM.modMask         = XM.mod4Mask
        , XM.terminal        = "termite"       
        , XM.workspaces      = myWorkspaces
        } `EZ.additionalKeysP` myKeyBindings -- KeysP because of emacs style






{-------------
- ManageHook -
-------------}
-- 'className' (WM_CLASS) generic
-- 'resource' (WM_NAME) specific
-- xprop | grep -ie "\(wm_class\|wm_name\)"
myManageHook = XM.composeAll
    [ XM.className =? "Firefox"          -->XM.doF(W.shift "1web")
    , XM.className =? "Evince"           -->XM.doF(W.shift "2doc")
    , XM.className =? "MuPDF"            -->XM.doF(W.shift "2doc")
    , XM.className =? "Termite"          -->XM.doF(W.shift "3term")
    , XM.className =? "MATLAB R2016b - academic use"        -->XM.doF(W.shift "5dev")
    , XM.className =? "termite-matlab"   -->XM.doF(W.shift "5dev")
    , XM.className =? "termite-cmus"     -->XM.doF(W.shift "6misc")
    , XM.className =? "termite-ncmpcpp"  -->XM.doF(W.shift "6misc")
    , XM.className =? "Thunderbird"      -->XM.doF(W.shift "7mail")
    , XM.className =? "termite-irssi"    -->XM.doF(W.shift "8chat")
    , XM.className =? "fiji-Main"        -->XM.doF(W.shift "9flt")
--    , XM.resource =? "sun-awt-X11-XDialogPeer" --> XM.doF(W.shift "9flt")
    ]




{--------------
- Keybindings -
--------------}

-- EZ Keys: http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Util-EZConfig.html
myKeyBindings = [

    -- Misc
      ("M-p",         XM.spawn dmenuCmd)
    , ("M-S-p",       XM.spawn passmenuCmd)
    , ("M-S-l",       XM.spawn "xautolock -locknow")
    , ("M-b",         XM.sendMessage Docks.ToggleStruts)
    --, ("M-g",       goToSelected defaultGSConfig)
    , ("M-<Return>",  XM.spawn "termite --class termite-scratch") -- terminal on other than 3:term workspaces
    , ("M-C-l",       XM.spawn "~/.bin/switch-light-dark.sh light")
    , ("M-C-d",       XM.spawn "~/.bin/switch-light-dark.sh dark")
    , ("M-q",         XM.spawn "~/.xmonad/compile-light-dark.sh && xmonad --restart")

    -- Screenshots ('sleep 0.2' to avoid 'giblib error: couldn't grab keyboard:Resource temporarily unavailable')
    , ("<Print>",      XM.spawn "sleep 0.2; scrot '/tmp/scrot_%Y-%m-%d_%H%M%S_$wx$h.png' -e 'mv $f ~/screenshots/'")
    , ("M1-<Print>",   XM.spawn "sleep 0.2; scrot --focused '/tmp/scrot_%Y-%m-%d_%H%M%S_$wx$h.png' -e 'mv $f ~/screenshots/'")
    , ("C-<Print>",    XM.spawn "sleep 0.2; scrot --delay 5 '/tmp/scrot_%Y-%m-%d_%H%M%S_$wx$h.png' -e 'mv $f ~/screenshots/'")
    , ("S-<Print>",    XM.spawn "sleep 0.2; scrot --select '/tmp/scrot_%Y-%m-%d_%H%M%S_$wx$h.png' -e 'mv $f ~/screenshots/'")

    -- Volume
    , ("<XF86AudioLowerVolume>",      XM.spawn "pamixer -d 5")
    , ("C-M1-<Down>",                 XM.spawn "pamixer -d 2") -- M1 is Alt_L according to xmodmap

    , ("<XF86AudioRaiseVolume>",      XM.spawn "pamixer -i 5")
    , ("C-M1-<Up>",                   XM.spawn "pamixer -i 2")

    , ("S-<XF86AudioLowerVolume>",    XM.spawn "pamixer -d 2")
    , ("S-<XF86AudioRaiseVolume>",    XM.spawn "pamixer -i 2")

    , ("<XF86AudioMute>",             XM.spawn "pamixer --toggle-mute")


    -- Brightness
    , ("<XF86MonBrightnessDown>",   XM.spawn "xbacklight -dec 10")
    , ("<XF86MonBrightnessUp>",   XM.spawn "xbacklight -inc 10")
    , ("S-<XF86MonBrightnessDown>",   XM.spawn "xbacklight -dec 2")
    , ("S-<XF86MonBrightnessUp>",   XM.spawn "xbacklight -inc 2")

    -- ResizableTall layout verticale (mod+[h/l] is only horizontal) 
    , ("M-a", XM.sendMessage Resize.MirrorShrink) 
    , ("M-z", XM.sendMessage Resize.MirrorExpand) 

    -- Warp
    , ("M-f",   Warp.warpToWindow 0.5 0.5)


    -- Music player (daemon) control
    , ("C-M1-<Home>",       XM.spawn "mpc pause")
    , ("C-M1-<Insert>",     XM.spawn "mpc play")
    , ("C-M1-<End>",        XM.spawn "mpc stop")
    , ("C-M1-<Page_Down>",  XM.spawn "mpc prev")
    , ("C-M1-<Page_Up>",    XM.spawn "mpc next")


    ]
{-    ++ 


    -- Physical screens
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    -- same as for (w,0), (e,1), (r,2)
    -- , ("M-w", PS.viewScreen 0)
    -- , ("M-S-w", PS.sendToScreen 0)
    [("M" ++ mask ++ key , f sc)
        | (key, sc) <- zip ["-w", "-e", "-r"] [0..]
        , (f, mask) <- [(PS.viewScreen, ""), (PS.sendToScreen, "-S")]]
-}


{--------
- Basics-
---------}
myWorkspaces = ["1web", "2doc", "3term", 
		"4dev", "5dev", "6misc",
		"7mail", "8chat", "9flt"]



{---------------
- dmenu config -
---------------}
myDMFont = "xft:Inconsolata:size=11:antialias=true"

dmenuOptions = " -i " -- case insensitive
    ++ " -fn " ++ myDMFont
    ++ " -nf " ++ myDMNormalFGColor
    ++ " -nb " ++ myDMNormalBGColor
    ++ " -sf " ++ myDMSelectedFGColor
    ++ " -sb " ++ myDMSelectedBGColor

dmenuCmd = "dmenu_run -p 'Run: '" ++ dmenuOptions
passmenuCmd = "passmenu -p 'Pass: '" ++ dmenuOptions



{----------
- Layouts -
----------}
myLayouts =

  Rename.renamed [Rename.Replace "T"] ( Resize.ResizableTall 1 (3/100) (1/2) [])

  ||| Rename.renamed [Rename.Replace "T!"] (XM.Mirror (Resize.ResizableTall 1 (3/100) (1/2) []))

  ||| Rename.renamed [Rename.Replace "F"] XM.Full
--        () 
--        (Rename.renamed [Rename.Replace "F"] XM.Full)



{----------------------
 - Statusbar and tray -
----------------------}
barCreator :: DBars.DynamicStatusBar
barCreator (XM.S sid) = do 
                        t <- XM.liftIO LT.getZonedTime
                        XM.trace (show t ++ ": XMonad barCreator " ++ show sid)
                        Run.spawnPipe barcmd 
                            where barcmd
                                    | sid == 0 = (xmobarCmd ++ " --screen " ++ show sid ++ " ~/.xmonad/xmobarrc")
                                    | sid >= 1 = (xmobarCmd ++ " --screen " ++ show sid ++ " ~/.xmonad/xmobarrc-secondary")

barDestroyer :: DBars.DynamicStatusBarCleanup
barDestroyer = do t <- XM.liftIO LT.getZonedTime
                  XM.trace (show t ++ ": XMonad barDestroyer")

myLogPP :: DLog.PP
myLogPP = DLog.defaultPP 
             {
               DLog.ppTitle =   DLog.xmobarColor myXmTitleColor "" . DLog.shorten 75
             , DLog.ppCurrent = DLog.xmobarColor myXmCurrentWSColor "" . DLog.wrap "[" "]"
             , DLog.ppVisible = DLog.xmobarColor myXmVisibleWSColor "" . DLog.wrap "(" ")"
             , DLog.ppUrgent =  DLog.xmobarColor myXmUrgentWSColor "" . DLog.wrap "{" "}"
             }

xmobarCmd =  "xmobar --fgcolor=" ++ myXmFgColor 
		  ++ " --bgcolor=" ++ myXmBgColor 

trayerCmd =  "killall trayer; "
          ++ "trayer --edge top --align right --widthtype request "
          ++ "--SetDockType true --SetPartialStrut true --height 19 "
          ++ "--tint 0x" ++ myTrBgColor ++ " --alpha 0 --transparent true"
