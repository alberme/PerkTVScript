--construct algorithim for checking stuck videos

--AutoTouch script for Perk TV app
--@author: Albert Martinez
--Source: perktv.lua

PERKTV_ID = "com.jutera.perktv";
errFlag, spriteNotFound = false, false;
--parameters: color, max number of counts
X_BUTTON = {11250603, 1};
VIDEOS_BUTTON = {16330829, 1};
VIDEO_PANE1 = {7673895, 1};
VIDEO_PANE2 = {7368818, 1};
GRAY = {13619151, 1};

--starts the app
function startApp()
  local attempts = 0;
 
  log("Starting Perk TV app");
  appRun(PERKTV_ID);
  usleep(6000000);
  
  while(not appIsActive(PERKTV_ID))
  do
    if(attempts == 3) then
      log("Perk TV failed to start, terminating script");
      alert("Perk TV failed to start, maybe app is not installed?");
      errFlag = true;
    end
    log("Perk TV did not open, attempting another run");
    appRun(PERKTV_ID);
    attempts = attempts + 1;
    usleep(6000000);
  end
end

--run function
function run()
  while(true)
  do
    startApp();
    findAndTapSprite(X_BUTTON, "X button");
    if(spriteNotFound) then
      break;
    end
    
    usleep(2000000);
 
    findAndTapSprite(VIDEOS_BUTTON, "Popular Videos");
    if(spriteNotFound) then
      break;
    end

    usleep(2000000);

    findAndTapSprite(VIDEO_PANE1, "First Video Pane");
    if(spriteNotFound) then
      break;
    end
 
    usleep(2000000);
 
    findAndTapSprite(VIDEO_PANE2, "First Video Button");
    if(spriteNotFound) then
      break;
    end
    
    playTime = os.time();
    log("Start pause, start playing videos");
 
    while(os.difftime(os.time(), playTime) < 400.0)
    do
      if(not appIsActive(PERKTV_ID)) then
        log("Error: App has terminated unexpectedly");
        break;
      end
    end
    usleep(300000000);
 
    log(string.format("End video play time: %.2f seconds", os.difftime(os.time(), playTime)));
    log("Pause expired, terminating Perk TV app");
    appKill(PERKTV_ID);
    usleep(2000000);
  end
end

--finds sprites on screen based on pixels and taps on them if found.
function findAndTapSprite(sprite, name)
  local found, attempts = false, 0;
  local coord;
 
  while(not found)
  do
    coord = findColor(sprite[1], sprite[2]);
    
    if(type(coord[1]) == "table") then
      for i, v in ipairs(coord) do
        log(string.format("Found color for %s at: x:%.2f, y:%.2f", name, v[1], v[2]));
        touchDown(1, v[1], v[2]);
        usleep(9000);
        touchUp(1, v[1],v[2]);
        usleep(9000);
        found = true;
      end
    else
      if(attempts == 5) then
        log(string.format("Error: Couldn't find %s", name));
        spriteNotFound = true;
        break;
      end
      log(string.format("Couldn't find %s, making another attempt.", name));
      attempts = attempts + 1;
    end
  end
end

--main
while(true)
do
  startApp();
  if(errFlag) then
    return
  end

  log("Running run function");
  run();
  if(spriteNotFound) then
    log("Restarting app");
    appKill(PERKTV_ID);
  end
errFlag, spriteNotFound = false;
end

