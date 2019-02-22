--AutoTouch script for Perk TV. Clicks through the app, checks for app crashes, yes prompt, and frozen ads.
--@author: Albert Martinez
--Source File: perktv_3.5.3-8.lua

PERKTV_ID = "com.jutera.perktv";
errFlag, spriteNotFound = false, false;
--time in nanoseconds
ONE_SECOND, TWO_SECONDS, THREE_SECONDS = 1000000, 2000000, 3000000;
SIX_SECONDS, NINE_SECONDS = 6000000, 9000000;
BLACK = 0;


--scans for buttons while playing videos
function scan(name, color, x, y)
  local found, firstCoordFound = false, false;
  local x1, y1, coord = 0, 0, nil;
  local time = os.time();
  
  if(x == nil) then
    x = 0.0;
  end
  if(y == nil) then
    y = 0.0;
  end
      
  coord = findColor(color);

  if(type(coord[1]) == "table") then
    for i, v in pairs(coord) do
      if(v[1] > x) then
        x1 = v[1];
        firstCoordFound = true;
        break;
      elseif(os.difftime(os.time(), time) > 1) then
        break;
      end
    end
        
    if(firstCoordFound) then
      for i, v in pairs(coord) do
        if(v[2] > y) then
          y1 = v[2];
          log(string.format("Found %s at %.2f, %.2f", name, x1, y1));
          tap(x1, y1);
          usleep(9000);
          break;
        end
      end
    end
  end
end

--coroutine that checks for frozen black screens
checkFrozenBlackScreens = coroutine.create(function()
  while(true) do
    local frozenCounts = 0;
    local c1, c2, c3, c4 = nil, nil, nil, nil;
          
    while(true) do
      c1 = getColor(140.0, 240.0); 
      c2 = getColor(180.0, 240.0);
      c3 = getColor(150.0, 260.0);
      c4 = getColor(180.0, 260.0);
      usleep(TWO_SECONDS);
      
      if(c1 == BLACK and c2 == BLACK and c3 == BLACK and c4 == BLACK) then
        frozenCounts = frozenCounts + 1;
        log("Frozen black screen counts: "..frozenCounts);
        if(frozenCounts == 10) then
          log("Frozen black screen detected, restarting app");
          appKill(PERKTV_ID);
          usleep(TWO_SECONDS);
          break;
        end
        coroutine.yield();
      else
        break;
      end     
    end
    coroutine.yield();
  end  
end)

--coroutine that checks for frozen ads
checkFrozenAds = coroutine.create(function()
  while(true) do  
    local attempts, frozen = 0, 0, true;
    local c1, c2, c11, c22 = nil, nil, nil, nil;
    local c3, c4, c33, c44 = nil, nil, nil, nil;
    usleep(THREE_SECONDS);
    
    while(frozen) do
      local frozenCounts = 0;
      c1 = getColor(140.0, 240.0);
      c2 = getColor(180.0, 240.0);
      c3 = getColor(150.0, 260.0);
      c4 = getColor(180.0, 260.0);
      
      while(frozenCounts ~= 5) do
        c11 = getColor(140.0, 240.0);
        c22 = getColor(180.0, 240.0);
        c33 = getColor(150.0, 260.0);
        c44 = getColor(180.0, 260.0);
        if(c1 == BLACK and c2 == BLACK and c3 == BLACK and c4 == BLACK) then
          frozen = false;
          break;
        elseif(c1 == c11 and c2 == c22 and c3 == c33 and c4 == c44) then         
          frozenCounts = frozenCounts + 1;
          usleep(TWO_SECONDS);
        else
          frozen = false;
          break;
        end
      end
      
      if(frozenCounts == 5) then
        if(attempts == 1) then
          log("Unable to unfreeze ad, restarting app");
          appKill(PERKTV_ID);
          break;
        end
        attempts = attempts + 1;
        log("Frozen ad detected, attempting to unfreeze");
        homeButtonDown();
        usleep(9000);
        homeButtonUp();
        usleep(ONE_SECOND);
        while(not appIsActive(PERKTV_ID)) do
          appRun(PERKTV_ID);
          usleep(9000);
        end
        usleep(SIX_SECONDS);
        scan("X Button", 11184810, 290.0, 70.0);
      end
      coroutine.yield();
    end
    coroutine.yield();
  end
end)

--starts the app and waits 9 seconds for loading.
function startApp()
  local attempts = 0;
 
  log("Starting Perk TV app");
  appRun(PERKTV_ID);
  usleep(NINE_SECONDS);
  
  while(not appIsActive(PERKTV_ID))
  do
    if(attempts == 3) then
      log("Perk TV failed to start, terminating script");
      alert("Perk TV failed to start, maybe app is not installed?");
      errFlag = true;
      break;
    end
    log("Perk TV did not open, attempting another run");
    appRun(PERKTV_ID);
    attempts = attempts + 1;
    usleep(NINE_SECONDS);
  end
end

--finds and taps sprites or buttons based on their colors
--use only for the initial screens
function findAndTap(name, color, x, y)
  local attempts, found, firstCoordFound = 0, false, false;
  local x1, y1, coord;
  
  if(x == nil) then
    x = 0.0;
  end
  if(y == nil) then
    y = 0.0;
  end
  
  while(not found) do 
    if(attempts == 10) then 
      spriteNotFound = true;
      break;
    end
    
    log("Attempts: " .. attempts);
    coord = findColor(color);
    
    if(type(coord[1]) == "table") then
      for i, v in ipairs(coord) do
        if(v[1] > x) then
          x1 = v[1]
          firstCoordFound = true;
          break;
        end        
      end
      
      if(firstCoordFound) then
        for i, v in ipairs(coord) do
          if(v[2] > y) then       
            y1 = v[2];
            log(string.format("Found color for %s at: x:%.2f, y:%.2f", name, x1, y1));
            tap(x1, y1);
            usleep(9000);
            found = true;
            break;
          end
        end
      else
        log(string.format("First coordinate for %s not found", name));
      end
      
      if(not found) then
        log("Error: failed to find both coords for "..name);
        attempts = attempts + 1;
        usleep(ONE_SECOND);
      end
    else
      attempts = attempts + 1;
      log(string.format("Failed to find %s. Attempts: %d", name, attempts));
      usleep(ONE_SECOND);
    end   
  end
end

--run function that guides through the app and checks for 
function run()
  local playTime, runTime;
  
  while(true) do 
    startApp();
    if(errFlag) then
      break;
    end
    log("Successfully started app");
    findAndTap("X button", 11184810, 280.0, 70.0);
    if(spriteNotFound) then
      log("Restarting Perk TV app due to no sprite found");
      break;
    end
    log("Successfully found X sprite");
    
    usleep(TWO_SECONDS);
    
    findAndTap("Popular Videos", 16265037);
    if(spriteNotFound) then
      log("Restarting Perk TV app due to no sprite found");
      break;
    end
    log("Successfully found Popular Videos sprite");
    
    usleep(TWO_SECONDS);
    
    findAndTap("Video Pane", 10514768);
    if(spriteNotFound) then
      log("Restarting Perk TV app due to no sprite found");
      break;
    end
    log("Successfully found Video Pane sprite");
   
    usleep(TWO_SECONDS);
    
    findAndTap("Video Play Button", 10514768);
    if(spriteNotFound) then
      log("Restarting Perk TV app due to no sprite found");
      break;
    end
    log("Successfully found Play Button sprite");
      
    playTime, runTime = os.time(), os.time(); 
    while(appIsActive(PERKTV_ID)) do
      scan("Yes Button", 31487);
      scan("Next Button", 4106239, 100.0, 352.0);
      --usleep(1000000);
      if(os.difftime(os.time(), playTime) > 60.0) then
        coroutine.resume(checkFrozenAds);
        coroutine.resume(checkFrozenBlackScreens);
        playTime = os.time();
      end    
    end
    log(string.format("App has terminated unexpectedly. Runtime: %.1fs", os.difftime(os.time(), runTime)));
    appKill(PERKTV_ID);
  end
end

--main
while(true) do
  run();
  if(errFlag) then
    alert("Perk TV failed to start, either your device turned off, the app isn't installed, or this script is fake and gay.");
    return
  end
  if(spriteNotFound) then
    appKill(PERKTV_ID);
    spriteNotFound = false;
  end
end