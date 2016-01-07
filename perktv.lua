--construct algorithim for checking stuck videos

--AutoTouch script for Perk TV app
--@author: Albert Martinez
--Source: perktv.lua

PERKTV_ID = "com.jutera.perktv";
errFlag = false;
-- parameters: table of colors, counts that should be attempted, table of coordinates to look in
X_BUTTON = {{{11250603,0,0}, {11184810,29,0}, {15592941,0,-35}, {12303291,29,-35}, {11184810,15,-18}}, 1, nil};
VIDEOS_BUTTON = {{{16330829,0,0}, {16264780,87,7}}, 1, nil};
VIDEO_PANE1 = {{{7673895,0,0}, {12546172,5,1}, {8993862,3,8}, {5838374,-1,4}, {10369865,2,-4}}, 1, nil};
VIDEO_PANE2 = {{{7368818,0,0}, {7367533,0,-59}, {6315873,54,-30}, {16316664,14,-29}}, 0, nil};

function startApp()
  local attempts = 0;
  
  log("Starting Perk TV app");
  appRun(PERKTV_ID);
  usleep(6000000);

  while(appState(PERKTV_ID) == "NOT RUNNING")
  do
    if(attempts == 3) then
      log("Perk TV failed to start, terminating script");
      alert("Perk TV failed to start, maybe app is not installed?");
      return
    end
    log("Perk TV did not open, attempting another run");
    appRun(PERKTV_ID);
    attempts = attempts + 1;
    usleep(6000000);
  end
end

function findAndTapSprite(sprite, name)
  local found, attempts = false, 0;
  local coord;
  
  while(not found)
  do
    coord = findColors(sprite[1], sprite[2], sprite[3]);
    
    if(type(coord[1]) == "table") then
      for i, v in ipairs(coord) do
        log(string.format("Found color for %s at: x:%f, y:%f", name, v[1], v[2]));
        touchDown(1, v[1], v[2]);
        usleep(9000);
        touchUp(1, v[1],v[2]);
        usleep(9000);
        found = true;
      end
    else
      if(attempts == 5) then
        log(string.format("Error: Couldn't find %s, terminating script.", name));
        alert(string.format("Error: Couldn't find %s, terminating script.", name));
        errFlag = true;
        return
      end
        log(string.format("Couldn't find %s, making another attempt.", name));
        attempts = attempts + 1;
    end
  end
end

adaptOrientation(ORIENTATION_TYPE.PORTRAIT);

while(true)
do
  startApp();
  findAndTapSprite(X_BUTTON, "X button");
  if(errFlag) then
    return
  end
      
  usleep(2000000);
  
  findAndTapSprite(VIDEOS_BUTTON, "Popular Videos");
  if(errFlag) then
    return
  end

  usleep(2000000);

  findAndTapSprite(VIDEO_PANE1, "First Video Pane");
  if(errFlag) then
    return
  end
  
  usleep(2000000);
  
  findAndTapSprite(VIDEO_PANE2, "First Video Button");
  if(errFlag) then
    return
  end

  playTime = os.time();
  log("Start timer, start playing videos");
  
  while(os.difftime(os.time(), playTime) < 300.0)
    do
      if(appState(PERKTV_ID) == "NOT RUNNING") then
        log("Error: App has terminated unexpectedly");
        break;
      end
    usleep(3000000);
    end
  
  log(string.format("End video play time: %.2f seconds", os.difftime(os.time(), playTime)));
  log("Terminating Perk TV app");
  appKill(PERKTV_ID);
  usleep(2000000);
end
