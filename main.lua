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

math.randomseed(os.time())

-- Heading changed to Advance Ludo version 1.1
activity.setTitle("Advance Ludo version 1.1")

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

-- ===== GAME DATA =====
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

-- ===== UI =====
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

-- ===== DEVELOPER SPLASH =====
function showDeveloper()
  AlertDialog.Builder(activity)
  .setTitle("Developer")
  .setMessage("Abdul Rao Amir") -- Updated developer name
  .setCancelable(false)
  .setPositiveButton("Continue", DialogInterface.OnClickListener{
    onClick=function()
      askUserName()
    end
  })
  .show()
end

-- ===== USER NAME (WITH SAVE) =====
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
  .setTitle("Welcome to Advance Ludo version 1.1")
  .setView(edit)
  .setCancelable(false)
  .setPositiveButton("OK", DialogInterface.OnClickListener{
    onClick=function()
      local name = edit.getText().toString()
      if name=="" then name="Player" end

      player.name = name
      editor.putString("playerName", name)
      editor.apply()

      updateStatus()
    end
  })
  .show()
end

-- ===== MODE SELECT =====
function selectMode()
  local options = {"52 Numbers Mode","100 Numbers Mode"}

  AlertDialog.Builder(activity)
  .setTitle("Select Mode")
  .setItems(options, DialogInterface.OnClickListener{
    onClick=function(dialog,which)
      if which==0 then
        TOTAL_STEPS=52
      else
        TOTAL_STEPS=100
      end
      speak("Mode selected. Total steps "..TOTAL_STEPS)
      resetBoard()
      rollBtn.setEnabled(true)
    end
  })
  .show()
end

-- ===== RESET =====
function resetBoard()
  player.pieces={0,0,0,0}
  robot.pieces={0,0,0,0}
  currentTurn="player"
  updateStatus()
end

-- ===== UPDATE STATUS =====
function updateStatus()
  local txt="Your Pieces:\n"
  for i=1,4 do
    txt=txt.."P"..i..":"..player.pieces[i].."  "
  end
  txt=txt.."\nRobot Pieces:\n"
  for i=1,4 do
    txt=txt.."R"..i..":"..robot.pieces[i].."  "
  end

  statusText.setText(txt)
  profileText.setText("Player: "..player.name.." | Level: "..player.level.." | Wins: "..player.wins.." | Kills: "..player.kills.." | Mode: "..TOTAL_STEPS)
end

-- ===== CHECK WIN =====
function checkWin(obj,name)
  local finished=0
  for i=1,4 do
    if obj.pieces[i]==TOTAL_STEPS then finished=finished+1 end
  end

  if finished==4 then
    speak(name.." wins the game")
    rollBtn.setEnabled(false)
    for i=1,4 do pieceButtons[i].setEnabled(false) end

    if name==player.name then
      player.wins=player.wins+1
      player.level=player.level+1
      speak("Level Up! Now level "..player.level)
    end

    updateStatus()
    return true
  end
  return false
end

-- ===== MOVE =====
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
      if side=="player" then
        player.kills=player.kills+1
      end
      speak("Piece killed!")
    end
  end

  updateStatus()
  return true
end

-- ===== ROBOT TURN =====
function robotTurn()
  currentTurn="robot"
  local roll=math.random(1,6)
  diceText.setText("Robot rolled: "..roll)
  speak("Robot rolled "..roll)

  for i=1,4 do
    if movePiece("robot",i,roll) then break end
  end

  if checkWin(robot,"Robot") then return end

  if roll==6 then
    Handler().postDelayed(robotTurn,800)
  else
    currentTurn="player"
    speak("Your turn")
  end
end

-- ===== PLAYER ROLL =====
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

        if lastRoll==6 then
          speak("Roll again")
        else
          Handler().postDelayed(robotTurn,800)
        end
      end
    end
  end
end

-- ===== BUTTON =====
startBtn.onClick=function()
  selectMode()
end

-- Start initialization
showDeveloper()