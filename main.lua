require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.os.*"
import "android.content.*"
import "android.graphics.*"
import "android.media.MediaPlayer"
import "android.speech.tts.TextToSpeech"
import "java.util.Locale"
import "http" -- Update ke liye zaroori hai

math.randomseed(os.time())

-- ===== CONFIGURATION =====
local currentVersion = "1.2"
local devName = "Abdul Rao Amir"
local storagePath = "/storage/emulated/0/解说/Tools/abe/main.lua"
local rawVersionUrl = "https://raw.githubusercontent.com/abdulraufamir559-prog/Advance-Ludo.-Mohsin-Ali./main/version.txt"
local rawCodeUrl = "https://raw.githubusercontent.com/abdulraufamir559-prog/Advance-Ludo.-Mohsin-Ali./main/main.lua"

-- ===== AUTO UPDATE SYSTEM =====
function checkUpdate()
  http.get(rawVersionUrl, function(code, content)
    if code == 200 and content then
      local onlineVersion = content:trim()
      if onlineVersion ~= currentVersion then
        showUpdateDialog(onlineVersion)
      end
    end
  end)
end

function showUpdateDialog(newV)
  AlertDialog.Builder(activity)
  .setTitle("Update Available!")
  .setMessage("New Version "..newV.." is ready. Do you want to update now?")
  .setCancelable(false)
  .setPositiveButton("Update Now", {onClick=function()
      downloadUpdate()
  end})
  .setNegativeButton("Later", nil)
  .show()
end

function downloadUpdate()
  local progress = ProgressDialog.show(activity, nil, "Updating Game... Please wait.")
  http.get(rawCodeUrl, function(code, content)
    progress.dismiss()
    if code == 200 then
      io.open(storagePath, "w"):write(content):close()
      announce("Update successful. Please restart the tool.")
      AlertDialog.Builder(activity)
      .setTitle("Success")
      .setMessage("Update Installed! Please restart the game to apply changes.")
      .setPositiveButton("OK", {onClick=function() activity.finish() end})
      .show()
    else
      print("Download Failed!")
    end
  end)
end

-- ===== SOUND SYSTEM =====
function playSound(path)
  try
    local mp = MediaPlayer()
    mp.setDataSource(path)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener(MediaPlayer.OnCompletionListener{
      onCompletion=function(m) m.release() end
    })
  catch e then end
end

local sWin = "/storage/emulated/0/ApkEditor/tmp/winner.mp3"
local sRoll = "/storage/emulated/0/ApkEditor/tmp/ball_coming.mp3"
local sOut = "/storage/emulated/0/ApkEditor/tmp/ball_out.mp3"
local sStart = "/storage/emulated/0/ApkEditor/tmp/card_shuffle.mp3"
local sMove = "/storage/emulated/0/ApkEditor/tmp/move.aac"
local sEntry = "/storage/emulated/0/ApkEditor/tmp/door.mp3"

-- ===== TTS SYSTEM =====
local tts
tts = TextToSpeech(activity, TextToSpeech.OnInitListener{
  onInit=function(status)
    if status==TextToSpeech.SUCCESS then
      tts.setLanguage(Locale.US)
    end
  end
})

function announce(text)
  if tts then tts.speak(text, TextToSpeech.QUEUE_FLUSH, nil, nil) end
end

-- ===== UI & GAME LOGIC (Briefly) =====
activity.setTitle("Advance Ludo v"..currentVersion)
layout = LinearLayout(activity)
layout.setOrientation(1)
layout.setPadding(40,40,40,40)

statusText = TextView(activity)
layout.addView(statusText)

rollBtn = Button(activity)
rollBtn.setText("Roll Dice")
layout.addView(rollBtn)

activity.setContentView(layout)

-- ===== INITIALIZATION =====
function startApp()
  checkUpdate() -- Update check karega
  playSound(sStart)
  announce("Welcome back to Advance Ludo, developed by " .. devName)
  
  AlertDialog.Builder(activity)
  .setTitle("Ludo v"..currentVersion)
  .setMessage("Developed by: "..devName)
  .setPositiveButton("Start", {onClick=function()
      rollBtn.setEnabled(true)
  end})
  .show()
end

startApp()