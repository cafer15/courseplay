local abs, ceil = math.abs, math.ceil;

function courseplay:handleMode7(vehicle, cx, cy, cz, refSpeed, allowedToDrive)
	if vehicle.isAIThreshing then
		if (vehicle.grainTankFillLevel * 100 / vehicle.grainTankCapacity) >= vehicle.cp.driveOnAtFillLevel then
			vehicle.maxnumber = #(vehicle.Waypoints) --TODO (Jakob): no need to calculate it each loop!
			local cx7, cz7 = vehicle.Waypoints[vehicle.maxnumber].cx, vehicle.Waypoints[vehicle.maxnumber].cz
			local lx7, lz7 = AIVehicleUtil.getDriveDirection(vehicle.rootNode, cx7, cty7, cz7);
			local fx,fy,fz = localToWorld(vehicle.rootNode, 0, 0, -3*vehicle.cp.turnRadius)
			local x7,y7,z7 = localToWorld(vehicle.rootNode, 0, 0, -15)
			vehicle.cp.mode7tx7 = x7
			vehicle.cp.mode7ty7 = y7
			vehicle.cp.mode7tz7 = z7
			if courseplay:isField(fx, fz) or vehicle.grainTankFillLevel >= vehicle.grainTankCapacity*0.99 then
				vehicle.lastaiThreshingDirectionX = vehicle.aiThreshingDirectionX
				vehicle.lastaiThreshingDirectionZ = vehicle.aiThreshingDirectionZ
				vehicle:stopAIThreshing()
				vehicle.cp.shortestDistToWp = nil
				vehicle.cp.nextTargets = {}
				if lx7 < 0 then
					courseplay:debug(nameNum(vehicle) .. ": approach from right", 11);
					vehicle.cp.curTarget.x, vehicle.cp.curTarget.y, vehicle.cp.curTarget.z = localToWorld(vehicle.rootNode, -(0.34*3*vehicle.cp.turnRadius) , 0, -3*vehicle.cp.turnRadius);
					courseplay:addNewTarget(vehicle, (0.34*2*vehicle.cp.turnRadius) , 0);
					courseplay:addNewTarget(vehicle, 0 , 3);
				else
					courseplay:debug(nameNum(vehicle) .. ": approach from left", 11);
					vehicle.cp.curTarget.x, vehicle.cp.curTarget.y, vehicle.cp.curTarget.z = localToWorld(vehicle.rootNode, (0.34*3*vehicle.cp.turnRadius) , 0, -3*vehicle.cp.turnRadius);
					courseplay:addNewTarget(vehicle, -(0.34*2*vehicle.cp.turnRadius) , 0);
					courseplay:addNewTarget(vehicle, 0 ,3);
				end
				vehicle.cp.mode7Unloading = true
				vehicle.cp.mode7GoBackBeforeUnloading = true
				courseplay:start(vehicle)
				vehicle.cp.speeds.sl = 3
				refSpeed = vehicle.cp.speeds.field
			else 
				return false;
			end
		else
			return false;
		end
	elseif vehicle.cp.mode7Unloading then
		vehicle.cp.speeds.sl = 3
		refSpeed = vehicle.cp.speeds.field
		if vehicle.cp.mode7GoBackBeforeUnloading then
			local dist = courseplay:distanceToPoint(vehicle, vehicle.cp.mode7tx7,vehicle.cp.mode7ty7,vehicle.cp.mode7tz7)
			if dist < 1 then
				vehicle.cp.mode7GoBackBeforeUnloading = false
				vehicle.recordnumber = 2
			end
		end
	else
		allowedToDrive = false
		courseplay:setGlobalInfoText(vehicle, 'WORK_END');
	end
	if vehicle.cp.modeState == 5 then
		local targets = #(vehicle.cp.nextTargets)
		local aligned = false
		local ctx7, cty7, ctz7 = getWorldTranslation(vehicle.rootNode);
		vehicle.cp.infoText = string.format(courseplay:loc("COURSEPLAY_DRIVE_TO_WAYPOINT"), vehicle.cp.curTarget.x, vehicle.cp.curTarget.z)
		cx = vehicle.cp.curTarget.x
		cy = vehicle.cp.curTarget.y
		cz = vehicle.cp.curTarget.z

		if courseplay.debugChannels[11] then 
			drawDebugLine(cx, cty7+3, cz, 1, 0, 0, ctx7, cty7+3, ctz7, 1, 0, 0); 
		end;

		vehicle.cp.speeds.sl = 3
		refSpeed = vehicle.cp.speeds.field
		local distance_to_wp = courseplay:distanceToPoint(vehicle, cx, y, cz);
		local distToChange = 4
		if vehicle.cp.shortestDistToWp == nil or vehicle.cp.shortestDistToWp > distance_to_wp then
			vehicle.cp.shortestDistToWp = distance_to_wp
		end
		if distance_to_wp > vehicle.cp.shortestDistToWp and distance_to_wp < 6 then
			distToChange = distance_to_wp + 1
		end
		if targets == 2 then 
			vehicle.cp.curTargetMode7 = vehicle.cp.nextTargets[2];
		elseif targets == 1 then
			if abs(vehicle.lastaiThreshingDirectionZ) > 0.1 then
				if abs(vehicle.cp.curTargetMode7.x-ctx7)< 3 then
					aligned = true
					courseplay:debug(nameNum(vehicle) .. ": aligned", 11);
				end
			else
				if abs(vehicle.cp.curTargetMode7.z-ctz7)< 3 then
					aligned = true
					courseplay:debug(nameNum(vehicle) .. ": aligned", 11);
				end
			end
		elseif targets == 0 then
			if distance_to_wp < 25 then
				vehicle.cp.speeds.sl = 3
				refSpeed = vehicle.cp.speeds.turn
			end
			if distance_to_wp < 15 then
				vehicle:setIsThreshing(true)
			end
			if abs(vehicle.lastaiThreshingDirectionX) > 0.1 then
				if abs(vehicle.cp.curTargetMode7.x-ctx7)< 5 then
					aligned = true
					courseplay:debug(nameNum(vehicle) .. ": aligned", 11);
				end
			else
				if abs(vehicle.cp.curTargetMode7.z-ctz7)< 5 then
					aligned = true
					courseplay:debug(nameNum(vehicle) .. ": aligned", 11);
				end
			end
		end
		if distance_to_wp < distToChange or aligned then
			vehicle.cp.shortestDistToWp = nil
			if targets > 0 then
				courseplay:setCurrentTargetFromList(vehicle, 1);
				vehicle.recordnumber = 2 
			else
				vehicle.cp.modeState = 0
				if vehicle.lastaiThreshingDirectionX ~= nil then
					vehicle.aiThreshingDirectionX = vehicle.lastaiThreshingDirectionX
					vehicle.aiThreshingDirectionZ = vehicle.lastaiThreshingDirectionZ
					courseplay:debug(nameNum(vehicle) .. ": restored vehicle.aiThreshingDirection", 11);
				end	
				vehicle:startAIThreshing(true)
				vehicle.cp.mode7Unloading = false
				courseplay:debug(nameNum(vehicle) .. ": start AITreshing", 11);
				courseplay:debug(nameNum(vehicle) .. ": fault: "..tostring(ceil(abs(ctx7-vehicle.cp.curTargetMode7.x)*100)).." cm X  "..tostring(ceil(abs(ctz7-vehicle.cp.curTargetMode7.z)*100)).." cm Z", 11);
			end
		end
	end

	return true, cx, cy, cz, refSpeed, allowedToDrive;
end;
