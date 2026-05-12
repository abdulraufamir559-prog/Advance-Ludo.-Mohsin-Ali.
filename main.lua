require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.os.*"
import "android.content.*"
import "android.graphics.*"
import "android.speech.tts.TextToSpeech"
import "java.util.Locale"
import "android.content.SharedPreferences"
import "com.androlua.Http" -- Required for update

math.randomseed(os.time())

-- ===== CONFIGURATION & UPDATE SYSTEM =====
local CURRENT_VERSION = "1.2"
local VERSION_URL = "https://raw.githubusercontent.com/abdulraufamir559-prog/Advance-Ludo.-Mohsin-Ali./main/version.txt"
local UPDATE_CODE_URL = "https://raw.githubusercontent.com/abdulraufamir559-prog/Advance-Ludo.-Mohsin-Ali./main/main.lua"
local PLUGIN_PATH = "/storage/emulated/0/解说/Tools/Advance Ludo. Mohsin Ali. /main.lua"

local updateInProgress = false
local mainHandler = Handler(Looper.getMainLooper())

activity.setTitle("Advance Ludo version " .. CURRENT_VERSION)

-- ===== SAVE SYSTEM =====
prefs = activity.getSharedPreferences("LudoProfile", Context.MODE_PRIVATE)
editor = prefs.edit()

-- ===== TTS INIT =====
local tts
tts = TextToSpeech(activity, TextToSpeech.OnInitListener{
  onInit=function(status)
    if status==TextToSpeech.SUCCESS then
      tts.setLanguage(Locale.ENGLISH)
    end
  end
})

function speak(text)
  if tts then
    tts.speak(text, TextToSpeech.QUEUE_FLUSH, nil, nil)
  end
end

-- ===== UPDATE FUNCTIONS =====

function trim(s)
    return s and s:gsub("^%s*(.-)%s*$", "%1") or ""
end

function checkUpdate()
    if updateInProgress then return end
    
    local timestamp = tostring(os.time())
    Http.get(VERSION_URL .. "?t=" .. timestamp, function(code, response)
        if code == 200 and response then
            local onlineVersion = trim(response)
            if onlineVersion ~= CURRENT_VERSION and onlineVersion ~= "" then
                Http.get(UPDATE_CODE_URL .. "?t=" .. timestamp, function(code2, mainCode)
                    if code2 == 200 and mainCode and trim(mainCode) ~= "" then
                        mainHandler.post(Runnable({
                            run = function()
                                local updateAlertDlg = AlertDialog.Builder(activity)
                                .setTitle("Update Available!")
                                .setMessage("Naya version (" .. onlineVersion .. ") dastiab hai.\nKya aap abhi update karna chahte hain?")
                                .setPositiveButton("Update Now", function()
                                    performUpdate(mainCode, onlineVersion)
                                end)
                                .setNegativeButton("Later", nil)
                                .show()
                            end
                        }))
                    end
                end)
            end
        end
    end)
end

function performUpdate(mainCode, onlineVersion)
    updateInProgress = true
    local tempPath = PLUGIN_PATH .. ".temp"
    
    local f = io.open(tempPath, "w")
    if f then
        f:write(mainCode)
        f:close()
        
        -- Old file remove aur rename
        os.remove(PLUGIN_PATH)
        if os.rename(tempPath, PLUGIN_PATH) then
            updateInProgress = false
            mainHandler.post(Runnable({
                run = function()
                    AlertDialog.Builder(activity)
                    .setTitle("Success")
                    .setMessage("App kamyabi se update ho gayi hai (v" .. onlineVersion .. ").")
                    .setPositiveButton("Restart", function()
                        activity.recreate() -- Restart the activity
                    end)
                    .show()
                end
            }))
        else
            updateInProgress = false
            print("Update Failed: Path error")
        end
    end
end

-- ===== GAME DATA & LOGIC =====
TOTAL_STEPS = 52
SAFE_ZONES = {1,9,14,22,27,35,40,48}

function isSafe(pos)
  for _,v in ipairs(SAFE_ZONES) do
    if v==pos then return true end
  end
  return false
end

player = {pieces={0,0,0,0}, wins=0, kills=0, level=1, name=""}
robot  = {pieces={0,0,0,0}}

currentTurn = "player"
lastRoll = 0

-- ===== UI SETUP =====
layout = LinearLayout(activity)
layout.setOrientation(1)

profileText = TextView(activity)
profileText.setTextSize(16)
layout.addView(profileText)

startBtn = Button(activity)
startBtn.setText("Start Game")
layout.addView(startBtn)

statusText = TextView(activity)
statusText.setTextSize(18)
layout.addView(statusText)

diceText = TextView(activity)
diceText.setTextSize(20)
layout.addView(diceText)

rollBtn = Button(activity)
rollBtn.setText("Roll Dice")
rollBtn.setEnabled(false)
layout.addView(rollBtn)

pieceButtons = {}
for i=1,4 do
  local btn = Button(activity)
  btn.setText("Move Piece "..i)
  btn.setEnabled(false)
  layout.addView(btn)
  pieceButtons[i]=btn
end

activity.setContentView(layout)

-- ===== GAME FLOW =====

function showDeveloper()
  AlertDialog.Builder(activity)
  .setTitle("Developer")
  .setMessage("Abdul Rao Amir")
  .setCancelable(false)
  .setPositiveButton("Continue", function()
      askUserName()
  end)
  .show()
end

function askUserName()
  local savedName = prefs.getString("playerName", nil)
  if savedName ~= nil then
    player.name = savedName
    updateStatus()
    return
  end

  local edit = EditText(activity)
  edit.setHint("Enter your name")

  AlertDialog.Builder(activity)
  .setTitle("Welcome")
  .setView(edit)
  .setCancelable(false)
  .setPositiveButton("OK", function()
      local name = edit.getText().toString()
      if name=="" then name="Player" end
      player.name = name
      editor.putString("playerName", name)
      editor.apply()
      updateStatus()
  end)
  .show()
end

function selectMode()
  local options = {"52 Numbers Mode","100 Numbers Mode"}
  AlertDialog.Builder(activity)
  .setTitle("Select Mode")
  .setItems(options, function(dialog,which)
      TOTAL_STEPS = (which==0) and 52 or 100
      speak("Mode selected. Total steps "..TOTAL_STEPS)
      resetBoard()
      rollBtn.setEnabled(true)
  end)
  .show()
end

function resetBoard()
  player.pieces={0,0,0,0}
  robot.pieces={0,0,0,0}
  currentTurn="player"
  updateStatus()
end

function updateStatus()
  local txt="Your Pieces:\n"
  for i=1,4 do txt=txt.."P"..i..":"..player.pieces[i].."  " end
  txt=txt.."\nRobot Pieces:\n"
  for i=1,4 do txt=txt.."R"..i..":"..robot.pieces[i].."  " end
  statusText.setText(txt)
  profileText.setText("Player: "..player.name.." | Level: "..player.level.." | Wins: "..player.wins.." | Kills: "..player.kills.." | Mode: "..TOTAL_STEPS)
end

function checkWin(obj,name)
  local finished=0
  for i=1,4 do if obj.pieces[i]==TOTAL_STEPS then finished=finished+1 end end
  if finished==4 then
    speak(name.." wins the game")
    rollBtn.setEnabled(false)
    if name==player.name then
      player.wins=player.wins+1
      player.level=player.level+1
    end
    updateStatus()
    return true
  end
  return false
end

function movePiece(side,index,roll)
  local obj = (side=="player") and player or robot
  local enemy = (side=="player") and robot or player
  local pos = obj.pieces[index]

  if pos==0 then
    if roll~=6 then return false end
    obj.pieces[index]=1
  else
    if pos+roll > TOTAL_STEPS then return false end
    obj.pieces[index]=pos+roll
  end

  for i=1,4 do
    if enemy.pieces[i]==obj.pieces[index] and not isSafe(obj.pieces[index]) then
      enemy.pieces[i]=0
      if side=="player" then player.kills=player.kills+1 end
      speak("Piece killed!")
    end
  end
  updateStatus()
  return true
end

function robotTurn()
  currentTurn="robot"
  local roll=math.random(1,6)
  diceText.setText("Robot rolled: "..roll)
  speak("Robot rolled "..roll)
  for i=1,4 do if movePiece("robot",i,roll) then break end end
  if checkWin(robot,"Robot") then return end
  if roll==6 then
    Handler().postDelayed(Runnable({run=robotTurn}), 800)
  else
    currentTurn="player"
    speak("Your turn")
  end
end

rollBtn.onClick=function()
  if currentTurn~="player" then return end
  lastRoll=math.random(1,6)
  diceText.setText("You rolled: "..lastRoll)
  speak("You rolled "..lastRoll)
  for i=1,4 do
    pieceButtons[i].setEnabled(true)
    pieceButtons[i].onClick=function()
      if movePiece("player",i,lastRoll) then
        for j=1,4 do pieceButtons[j].setEnabled(false) end
        if checkWin(player,player.name) then return end
        if lastRoll==6 then speak("Roll again")
        else Handler().postDelayed(Runnable({run=robotTurn}), 800) end
      end
    end
  end
end

startBtn.onClick=function() selectMode() end

-- ===== STARTUP =====
showDeveloper()

-- Check for updates after 2 seconds of launch
mainHandler.postDelayed(Runnable({
    run = function()
        checkUpdate()
    end
}), 2000)