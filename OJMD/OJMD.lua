local Heute = date("%d.%m.%y");
local CharClass, classFileName, CharClassIndex = UnitClass("player");
local CharID = GetRealmName("player") .. "::" .. UnitName("player");
local OJMD_UpdateInterval = 1.0;

local ClassColors = {}
	ClassColors[0] = "|cffFFFFFF";
	ClassColors[1] = "|cffC79C6E";
	ClassColors[2] = "|cffF58CBA";
	ClassColors[3] = "|cffABD473";
	ClassColors[4] = "|cffFFF569";
	ClassColors[5] = "|cffFFFFFF";
	ClassColors[6] = "|cffC41F3B";
	ClassColors[7] = "|cff0070DE";
	ClassColors[8] = "|cff69CCF0";
	ClassColors[9] = "|cff9482C9";
	ClassColors[10] = "|cff00FF96";
	ClassColors[11] = "|cffFF7D0A";
	ClassColors[12] = "|cffC41F3B";
    ClassColors[13] = "|cffC41F3B";
    
local MaxLevel = 120
local CurrentCharData = {}
local count = 0
local currentMoney = 0
local currentEP = 0
local currentDauer = 0

OJMD_SessionVars = {}
OJMD_SessionVars.Gold = 0
OJMD_SessionVars.GoldGesamt = 0
OJMD_SessionVars.Gold = 0
OJMD_SessionVars.EP = 0
OJMD_SessionVars.Dauer = 0
OJMD_SessionVars.DauerStart = 0
OJMD_SessionVars.Ausgaben = 0
OJMD_SessionVars.EPRest = 0


function OJMD_Init() 

    if not DataDB then
        DataDB = {}                                
    end
    
    if not DataDB[ Heute ] then
        DataDB[ Heute] = {}
    end  

    if not vars then
        vars = {
            EP = 0,
            EPstart = 0,
            EPrest = 0,
            Gold = 0,
            Goldstart=0,
            Goldaus=0,
            Class = CharClassIndex,
            Name = UnitName("player"),
            Dauerstart = 0,
            Dauer = 0
        }
    end

    if not DataDB[Heute][CharID] then
        DataDB[Heute][CharID] = {
            EP = 0,
            EPIni = 0,
            Gold = 0,
            GoldIni = 0,
            IniGold = 0,
            Ausgaben = 0,
            Dauer = 0,
            DauerIni = 0,
        }
    end     


    if not Ini then
        Ini = {
            Name = '',
            Difficulty = '',
            Goldstart = 0,
            Gold = 0,
            EP = 0,
            EPstart = 0,
            TimerStart = 0,
            Dauer = 0,
            Run = false   
        }
    end

    if not RaidDB then RaidDB = {} end
end    

function OJMD_OnEvent(self, event, ...)
    
    if ( event == "VARIABLES_LOADED" ) then
                                            
        OJMD_Init()  
        OJMD:SetHeight ( 70 )      

        if UnitLevel("player") == MaxLevel then
            OJMD:SetWidth ( 200 )      
            AnzeigeEPCurrent:Hide()
            AnzeigeEPGesamt:Hide()
            AnzeigeInstanceEP:Hide()
        end


        print( "Willkommen zurück " .. ClassColors[ vars.Class ] .. UnitName("player") .."|r !" )

    end
    
    if ( event == "PLAYER_ENTERING_WORLD" ) then 
        
        OJMD_UpdateGold()         
        OJMD_UpdateEP()
        OJMD_UpdateDauer() 

        OJMD_TableBrowser.Init()

        inInstance, instanceType = IsInInstance();
        if( (inInstance == 1) or (inInstance == true) ) then

            local Ininame, Initype, difficultyIndex, difficultyName, maxPlayers,dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()

            if ( Ini.Run ~= true ) then
                Ini.Name        = Ininame
                Ini.Typ         = Initype
                Ini.Difficulty  = difficultyName
                Ini.TimerStart  = GetTime()
                Ini.Goldstart   = GetMoney("player")
                Ini.EPstart     = UnitXP("player") 
                Ini.Run = true

                --print("Timer wurde gestartet!")
                OJMD:SetHeight ( 100 )
            end 

            AnzeigeInstanceName:SetText( Ininame )
            AnzeigeInstanceDifficulty:SetText( difficultyName )
            AnzeigeInstanceDauer:SetText( makeTimeString( Ini.Dauer ) )
            AnzeigeInstanceGold:SetText( formatGoldString( Ini.Gold ) )
            AnzeigeInstanceEP:SetText( formatiereEP( Ini.EP ) )    
            
            print("Ini EP: " .. Ini.EP )
        else
               
            --[[ Instance wurde verlassen ]]
            if ( Ini.Run ) then

                DataDB[ Heute][CharID].GoldIni     = DataDB[ Heute][CharID].GoldIni   + Ini.Gold
                DataDB[ Heute][CharID].EPIni       = DataDB[ Heute][CharID].EPIni     + Ini.EP
                DataDB[ Heute][CharID].DauerIni    = DataDB[ Heute][CharID].DauerIni  + Ini.Dauer

                --[[ Instance Run speichern ]]
                if not RaidDB[ Ini.Typ ] then RaidDB[ Ini.Typ ] = {} end

                local rundata = { Ini.Name , Ini.Difficulty ,  Ini.Gold , Ini.EP , Ini.Dauer , Heute , GetTime(), date("%H:%M") }            

                table.insert( RaidDB[ Ini.Typ ] , rundata )

                --[[ Rücksetzen der Daten ]]
                Ini.Gold    = 0
                Ini.EP      = 0
                Ini.Dauer   = 0
                Ini.Run     = false
                OJMD:SetHeight ( 70 )

                print("Ini wurde verlassen!")
                OJMD_TableBrowser.Init()
            end    
            
            AnzeigeInstanceName:SetText("")
            AnzeigeInstanceDifficulty:SetText("")
            AnzeigeInstanceDauer:SetText("")
            AnzeigeInstanceGold:SetText("")
            AnzeigeInstanceEP:SetText("")          

        end
    end
    
    if ( event == "PLAYER_MONEY" ) then                   
        OJMD_UpdateGold() 
        OJMD_UpdateDauer()       
    end
    
    if event == "PLAYER_XP_UPDATE" then    
        OJMD_UpdateEP()  
        OJMD_UpdateDauer()
    end

    if event == "PLAYER_LEVEL_UP" then 
        if ( Ini.Run ) then                
            Ini.EPstart = ( 0 - OJMD_SessionVars.EPRest )
        end
        vars.EPstart = ( 0 - OJMD_SessionVars.EPRest )  
        OJMD_UpdateEP()  
        OJMD_UpdateDauer()    
        print("Player Level UP!!!")   
    end
end


function OJMD_UpdateGold() 

    if ( currentMoney == nil ) or ( currentMoney <= 0 ) then
        currentMoney = GetMoney("player") 
        --print( "init - Start Gold: " .. currentMoney .. " -> " .. GetMoney("player") )
    end

    local new_money;
    new_money = GetMoney("player");
        

    if((new_money == nil) or (new_money <= 0)) then
        new_money = 0;
    end
    
    -- add the diff to character's money
    if((new_money - currentMoney ) < 0) then
        DataDB[Heute][CharID].Ausgaben = DataDB[Heute][CharID].Ausgaben + (new_money - currentMoney)
    end

    OJMD_SessionVars.Gold = OJMD_SessionVars.Gold + (new_money - currentMoney);
    
    
    DataDB[Heute][CharID].Gold = DataDB[Heute][CharID].Gold + (new_money - currentMoney);
    
    AnzeigeGoldCurrent:SetText( formatGoldString( OJMD_SessionVars.Gold ) )
    AnzeigeGoldGesamt:SetText( formatGoldString( DataDB[Heute][CharID].Gold ) )
    
    -- set for next money add
    currentMoney = new_money;

    -- PlaySound(891, "Master")    
    if ( Ini.Run ) then                
        Ini.Gold        = Ini.Gold + ( GetMoney("player") - Ini.Goldstart )
        Ini.Goldstart   = GetMoney("player")
        AnzeigeInstanceGold:SetText( formatGoldString( Ini.Gold ) )
        --print( "Gold: " ..  Ini.Gold )
    end
end 

function OJMD_UpdateEP()
    
    if ( currentEP == nil ) or ( currentEP <= 0 ) then
        currentEP = UnitXP("player") 
        --print( "init - Start EP: " .. currentEP .. " -> " .. UnitXP("player") )
    end  

    local new_EP
    new_EP = UnitXP("player")

    if((new_EP == nil) or (new_EP <= 0)) then
        new_EP = 0;
    end
    
    -- add the diff to character's money
    if((new_EP - currentEP ) > 0) then
        OJMD_SessionVars.EP = OJMD_SessionVars.EP + (new_EP - currentEP);
        DataDB[ Heute][CharID].EP = DataDB[ Heute][CharID].EP + (new_EP - currentEP);
    end
    
    OJMD_SessionVars.EPRest = UnitXPMax("player") - UnitXP("player");
    
    
    AnzeigeEPCurrent:SetText( formatiereEP( OJMD_SessionVars.EP ) )
    AnzeigeEPGesamt:SetText( formatiereEP( DataDB[ Heute][CharID].EP ) )
    
    
    currentEP = new_EP
    
    if ( Ini.Run ) then                
        Ini.EP          = Ini.EP + ( UnitXP("player") - Ini.EPstart )    
        Ini.EPstart = UnitXP("player")      
        --print( "EP: (Ini)" ..  Ini.EP )
        AnzeigeInstanceEP:SetText( formatiereEP( Ini.EP ) )
    end
end 

function OJMD_UpdateDauer()
    
    if((OJMD_SessionVars.DauerStart == nil) or (OJMD_SessionVars.DauerStart <= 0)) then
        OJMD_SessionVars.DauerStart = GetTime()
    end
    
    if((DataDB[ Heute][CharID].DauerStart == nil) or (DataDB[ Heute][CharID].DauerStart <= 0)) then
        DataDB[ Heute][CharID].DauerStart = GetTime()
    end
    
    if ( Ini.Run ) then                
        Ini.Dauer       = ( GetTime() - Ini.TimerStart )
        --print( "Dauer: " ..  Ini.Dauer )
        AnzeigeInstanceDauer:SetText( makeTimeString( Ini.Dauer ) )
    end

    OJMD_SessionVars.Dauer = ( GetTime() - OJMD_SessionVars.DauerStart )    

    DataDB[ Heute][CharID].Dauer = ( GetTime() - DataDB[ Heute][CharID].DauerStart )

    AnzeigeDauerCurrent:SetText( makeTimeString( OJMD_SessionVars.Dauer ) )
    AnzeigeDauerGesamt:SetText( makeTimeString( DataDB[ Heute][CharID].Dauer ) )

end 


function formatiereEP( EP )
	local str = "";
	if ( EP > 1000 ) then
		str = round( ( EP / 1000 ), 2 )  .. "k EP";
    elseif( EP > 1000000 ) then
        str = round( ( EP / 1000000 ) , 2 ) .. "m EP"
    else 
		str = EP .. " EP";
	end 

	return str;
end	

function round(num, numDecimalPlaces)
	if numDecimalPlaces and numDecimalPlaces>0 then
	  local mult = 10^numDecimalPlaces
	  return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end

function makeTimeString( seconds )

    local seconds = tonumber( seconds )

    if seconds <= 0 then
        return "00:00:00"
    else
        hours = string.format("%02.f", math.floor( seconds/3600 ) )
        mins  = string.format("%02.f", math.floor( seconds/60 - ( hours*60 ) ) )
        secs  = string.format("%02.f", math.floor( seconds - hours * 3600 - mins * 60  ) )
        return hours .. " : " .. mins
        --return hours .. " : " .. mins .. " : " .. secs

    end    
end

--[[ Formatiere Gold String]]
function formatGoldString( gold )
	local str = "";
	local negative = false;

	if( gold > 0 ) then
		gold = gold -- + 101
	end

	if ( gold < 0 ) then
		str = "|cffff0000 -" .. GetCoinTextureString( ( gold * -1 ) ).. "|r";
		negative = true;
	else
		str = "|cffFFFFFF " .. GetCoinTextureString( gold ) .. "|r";
	end
	return str , negative
end

do 
    local toggleFrame = false

function OJMD_ButtonClick()      
    if toggleFrame == true then
        OJMD_ListFrame:Hide()
        toggleFrame = false
    else
        OJMD_ListFrame:Show()
        toggleFrame = true
    end
end


end     

MyModData = {}

function OJMD_LoadData_INI()
    -- if( RaidDB.party ) then		
    --     for k,v in pairs( RaidDB.party ) do
    --         print("k: " .. k .. " -> " .. v[1] )
    --         if ( k ) then
    --             MyModData[k] = v[1]
    --         end
    --     end
    -- end

    -- --    print( "Count: " .. table.getn(RaidDB.party) )

    -- for i=1,50 do
    --     MyModData[i] = "Test "..math.random(100)
    --   end
    --   MyModScrollBar:Show() 

    --   --print("GetGlobal: " ..  getglobal( OJMD_ListEntry:GetName() .. "Name") )

      do
        local entry = CreateFrame("Button","$parentEntry1",OJMD_ListFrame,"OJMD_ListEntry")
        entry:SetID(1)
        entry:Hide()
        entry:SetText("TEST")
        entry:SetPoint("TOPLEFT",4,-28)
        for i=2, table.getn(RaidDB.party) do
            local entry = CreateFrame("Button","$parentEntry" .. i,OJMD_ListFrame,"OJMD_ListEntry")
            entry:SetID(i)
            entry:SetText("TEST")
            entry:SetPoint("TOP","$parentEntry" .. (i-1),"BOTTOM")
            entry:Hide()
        end
    end

    for i = 1, table.getn(RaidDB.party) do
        local entry = RaidDB.party[i]
        local frame = getglobal("OJMD_ListFrameEntry" .. i)
        if entry then
            frame:Show()
            getglobal(frame:GetName() .. "ID"):SetText(i)
            getglobal(frame:GetName() .. "Name"):SetText( entry[1] )
            getglobal(frame:GetName() .. "Difficulty"):SetText( entry[2] )
            getglobal(frame:GetName() .. "Gold"):SetText( formatGoldString( entry[3] ) )
            getglobal(frame:GetName() .. "EP"):SetText( formatiereEP( entry[4] ) )
            getglobal(frame:GetName() .. "Dauer"):SetText( makeTimeString( entry[5] ) )
            getglobal(frame:GetName() .. "Datum"):SetText( entry[6] )
            if entry.isSelected then
                _G[frame:GetName() .. "BG"]:Show()
            else
                _G[frame:GetName() .. "BG"]:Hide()
            end
        else
            frame:Hide()
        end

    end
 
end

function OJMD_List_Update()
    for i = 1, table.getn(RaidDB.party) do
        local entry = RaidDB.party[i]
        local frame = getglobal("OJMD_ListEntryEntry" .. i)
        if entry then
            frame:Show()
            getglobal(frame:GetName() .. "Name"):SetText(entry[1])
            getglobal(frame:GetName() .. "Difficulty"):SetText(entry[2])
        end

    end
end


-- function MyModScrollBar_Update()
--     local line; -- 1 through 5 of our window to scroll
--     local lineplusoffset; -- an index into our data calculated from the scroll offset
--     FauxScrollFrame_Update(MyModScrollBar,50,5,16);
--     for line=1,5 do
--       lineplusoffset = line + FauxScrollFrame_GetOffset(MyModScrollBar);
--       if lineplusoffset <= 50 then
--         --getglobal(OJMD_ListEntry:GetName() .. "Name"):SetText("TEST")        
--         --getglobal(OJMD_ListEntry:GetName() .. "Difficulty"):SetText("TEST")        
--         getglobal("MyModEntry"..line):SetText(MyModData[lineplusoffset]);
--         getglobal("MyModEntry"..line):Show();
--       else
--         getglobal("MyModEntry"..line):Hide();
--       end
--     end
--   end

--OJMD_TableBrowser.Update()

local MAX_LISTENTRYS = 0
local db = {}

OJMD_TableBrowser = {}

do
    function OJMD_TableBrowser.Init()
     --print('INIT(): '  .. table.getn(RaidDB) )
        local tempMax = 0
        for i,v in pairs( RaidDB ) do            
            if table.getn(RaidDB[i]) > tempMax then
                MAX_LISTENTRYS = table.getn(RaidDB[i])
                tempMax = table.getn(RaidDB[i])
            end
        end

        -- local kids = { OJMD_Liste:GetChildren() };

        --     for _, child in ipairs(kids) do
        --         DEFAULT_CHAT_FRAME:AddMessage(child:GetID() .. " -- " .. child:GetName() );
        --     end

        -- print("ListEntrys Count: " .. MAX_LISTENTRYS )
        
        if ( RaidDB.party ~= nil ) then if table.getn( RaidDB.party ) then OJMD_ListFrameINI:Show() end end
        if ( RaidDB.raid ~= nil ) then if table.getn( RaidDB.raid ) then OJMD_ListFrameRAID:Show() end end
        if ( RaidDB.pvp ~= nil ) then if table.getn( RaidDB.pvp ) then OJMD_ListFramePVP:Show() end end
        if ( RaidDB.scenario ~= nil ) then if table.getn( RaidDB.scenario ) then OJMD_ListFrameSCENARIO:Show() end end

        OJMD_TableBrowser.LoadData()
    end
end

    do 

    function OJMD_TableBrowser.LoadData()
        do
            local entry = CreateFrame("Button","$parentEntry1",OJMD_Liste,"OJMD_ListEntry")
            entry:SetID(1)
            entry:SetPoint("TOPLEFT",4,-28)
            for i=2, ( table.getn( db ) + 20 ) do
                local entry = CreateFrame("Button","$parentEntry" .. i,OJMD_Liste,"OJMD_ListEntry")
                entry:SetID(i)
                entry:SetPoint("TOP","$parentEntry" .. (i-1),"BOTTOM")
            end
        end
    end
end

    function OJMD_TableBrowser.ChooseTable( table )
        db = RaidDB[ table ]
        OJMD_TableBrowser.Update()
    end 

do 
    function OJMD_TableBrowser.Update()

        for i = 1, MAX_LISTENTRYS do
            local f = getglobal("OJMD_ListeEntry" .. i)
            f:Hide()
        end

        for i = 1, table.getn( db ) do
            local entry = db[i] -- + OJMD_ListScrollFrame.offset]
            local frame = getglobal("OJMD_ListeEntry" .. i)
            if entry then
                frame:Show()
                getglobal(frame:GetName() .. "ID"):SetText(i)
                getglobal(frame:GetName() .. "Name"):SetText( entry[1] )
                getglobal(frame:GetName() .. "Difficulty"):SetText( entry[2] )
                getglobal(frame:GetName() .. "Gold"):SetText( formatGoldString( entry[3] ) )
                getglobal(frame:GetName() .. "EP"):SetText( formatiereEP( entry[4] ) )
                getglobal(frame:GetName() .. "Dauer"):SetText( makeTimeString( entry[5] ) )
                getglobal(frame:GetName() .. "Datum"):SetText( entry[6] )
                if entry.isSelected then
                    _G[frame:GetName() .. "BG"]:Show()
                else
                    _G[frame:GetName() .. "BG"]:Hide()
                end
            else
                frame:Hide()
            end
    
        end
    end

    --FauxScrollFrame_Update(OJMD_ListFrameScrollFrame, 20 , 5, 16)

end

do
    local currSort = 1
    local currOrder = "asc"
    local translateID = {1,1,2,3,4,5,7} --{ Ini.Name , Ini.Difficulty ,  Ini.Gold , Ini.EP , Ini.Dauer , Heute , GetTime(), date("%H:%M") }        

    function OJMD_TableBrowser.SortTables( id )

        if currSort == id then
            if currOrder == "asc" then
                currOrder = "asc"
            else
                currOrder = "desc"
            end
        elseif id then
            currSort = translateID[ id ]
            currOrder = "desc"
        end

        print("Sort ID: " .. id .. " -> " .. translateID[id] )

        table.sort( db, function(v1,v2) 
            if currOrder == "desc" then
                return v1[currSort] > v2[currSort]
            else
                return v1[currSort] < v2[currSort]
            end
        end)
        OJMD_TableBrowser.Update()
    end
end
do 
    local selection = nil

    function OJMD_TableBrowser.SelectEntry( id )

        -- if id ~= nil then
        --     print("ID: " .. id)
        --     table.remove( db , id )
        -- end

        -- OJMD_TableBrowser.Update()


        if selection then
            for i = 1, table.getn(db) do
                _G["OJMD_ListEntry" .. i .. "BG"]:Hide()
            end
            selection.isSelected = nil
        end
        selection = db[ id ]
        selection.isSelected = true
    end
    function OJMD_TableBrowser.IsSelected( id )
        return db[ id ] == selection
    end


end

function FauxScrollFrame_OnVerticalScroll( self , value , itemHeight, updateFunction)
    local scrollbar = _G[self:GetName() .. "ScrollBar"]
    scrollbar:SetValue( value )
    self.offset = floor( ( value / itemHeight ) + 0.5 )
    updateFunction( self )
end

