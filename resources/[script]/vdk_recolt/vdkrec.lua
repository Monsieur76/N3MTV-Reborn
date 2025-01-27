--Variables
local recoltDistance = 3
local timeForRecolt = 4000 --1000 for 1 second
--
nbPolice = 0
local near
local jobId
JOBS = {}

RegisterNetEvent("jobs:getJobs")
RegisterNetEvent("cli:getJobs")
RegisterNetEvent("recolt:getcop")

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("jobs:getJobs")
end)

-- Get the list of all jobs in the database and create the blip associated
AddEventHandler("cli:getJobs", function(listJobs)
    JOBS = listJobs
    Citizen.CreateThread(function()
        --for _, item in pairs(JOBS) do
        --    setBlip(item.fx, item.fy, item.fz, 17)
        --    setBlip(item.tx, item.ty, item.tz, 18)
        --    setBlip(item.sx, item.sy, item.sz, 19)
        --end
    end)
end)

-- Control if the player of is near of a place of job
function IsNear()
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)
    for k, item in ipairs(JOBS) do
        local distance_field = GetDistanceBetweenCoords(item.fx, item.fy, item.fz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
        local distance_treatment = GetDistanceBetweenCoords(item.tx, item.ty, item.tz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
        local distance_seller = GetDistanceBetweenCoords(item.sx, item.sy, item.sz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
        if (distance_field <= recoltDistance) then
            jobId = k
            return 'field'
        elseif (distance_treatment <= recoltDistance) then
            jobId = k
            return 'treatment'
        elseif (distance_seller <= recoltDistance) then
            jobId = k
            return 'seller'
        end
    end
end

-- Display the message of recolting/treating/selling and trigger the associated event(s)
function recolt(text, rl)
    if (text == 'Récolte') then
        TriggerEvent("mt:missiontext", text .. ' en cours de ~g~' .. tostring(JOBS[jobId].raw_item) .. '~s~...', timeForRecolt - 800)
        Citizen.Wait(timeForRecolt - 800)
        TriggerEvent("player:receiveItem", tonumber(JOBS[jobId].raw_id), 1)
        TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(JOBS[jobId].raw_item) .. '~s~...', 800)
    elseif (text == 'Traitement') then
        TriggerEvent("mt:missiontext", text .. ' en cours de ~g~' .. tostring(JOBS[jobId].raw_item) .. '~s~...', timeForRecolt - 800)
        Citizen.Wait(timeForRecolt - 800)
        TriggerEvent("player:looseItem", tonumber(JOBS[jobId].raw_id), 1)
        TriggerEvent("player:receiveItem", tonumber(JOBS[jobId].treat_id), 1)
        TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(JOBS[jobId].treat_item) .. '~s~...', 800)
    elseif (text == 'Vente') then
		if nbPolice > 0 then
			TriggerEvent("mt:missiontext", text .. ' en cours de ~g~' .. tostring(JOBS[jobId].treat_item) .. '~s~...', timeForRecolt - 800)
			Citizen.Wait(timeForRecolt - 800)
			-- local pourcentage = 1
			-- for i=0,nbPolice,1 do
				-- pourcentage = pourcentage * 1.2
			-- end
			-- local price = (tonumber(JOBS[jobId].price)*pourcentage)
			local price = tonumber((JOBS[jobId].price)*(1.2^nbPolice))
			TriggerEvent("player:sellItemSale", tonumber(JOBS[jobId].treat_id), tonumber(math.floor(price)))
			TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(JOBS[jobId].treat_item) .. '~s~...', 800)
		end
    end
    Citizen.Wait(800)
end

function setBlip(x, y, z, num)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, tonumber(num))
    SetBlipAsShortRange(blip, true)
end

-- Constantly check the position of the player
Citizen.CreateThread(function()
    Citizen.Wait(5000)

    while true do
        Citizen.Wait(1)
        near = IsNear()
        if (exports.vdk_inventory:notFull() == true) then
            if (near == 'field') then
                recolt('Récolte', '+1')
            elseif (near == 'treatment' and exports.vdk_inventory:getQuantity(JOBS[jobId].raw_id) > 0) then
                recolt('Traitement', '+1')
            elseif (near == 'seller' and exports.vdk_inventory:getQuantity(JOBS[jobId].treat_id) > 0) then
				if nbPolice > 0 then
					recolt('Vente', '-1')
				else
					TriggerEvent("mt:missiontext", 'il faut au moins 1 Policiers en service pour Vendre', 800)
				end
            end
        else
			if (near == 'field') then
                TriggerEvent("mt:missiontext", 'Inventaire Plein', 800)
            elseif (near == 'treatment' and exports.vdk_inventory:getQuantity(JOBS[jobId].raw_id) > 0) then
                recolt('Traitement', '+1')
            elseif (near == 'seller' and exports.vdk_inventory:getQuantity(JOBS[jobId].treat_id) > 0) then
				if nbPolice > 0 then
					recolt('Vente', '-1')
				else
					TriggerEvent("mt:missiontext", 'il faut au moins 1 Policiers en service pour Vendre', 800)
				end
            end
        end
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(30000)
		TriggerServerEvent('recolt:stestcop')
	end
end)
	
AddEventHandler("recolt:getcop", function(nbPolicier)
	nbPolice = nbPolicier
end)
			
			
function Chat(debugg)
    TriggerEvent("chatMessage", '', { 0, 0x99, 255 }, tostring(debugg))
end