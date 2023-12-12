
function getNumericalValue(condition)
    if condition == "Producing/Exporting" then
        return 10
    elseif condition == "Producing/Charging" then
        return 9
    elseif condition == "Producing/Discharging" then
        return 8
    elseif condition == "Discharging" then
        return 7
    elseif condition == "Producing/Discharging/Importing" then
        return 6
    elseif condition == "Discharging/Importing" then
        return 5
    elseif condition == "Importing/Producing" then
        return 4
    elseif condition == "Importing" then
        return 3
    elseif condition == "Discharging/Exporting" then
        return 1
    else
        return nil -- Return nil for undefined conditions
    end
end

function calculateMode(importedenergy, exportedenergy, consumedenergy, producedenergy, dischargedenergy, chargedenergy)

	if (importedenergy < 100) then
		importenergy = 0
	end
	if (exportedenergy < 100) then
		exportenergy = 0
	end
	if (consumedenergy < 100) then
		consumedenergy = 0
	end

	if producedenergy > 0 and exportedenergy > 0 then
		return 10, "Producing/Exporting"
	elseif producedenergy > 0 and chargedenergy > 0 then
                return 9, "Producing/Charging"
	elseif producedenergy > 0 and dischargedenergy > 0 then
                return 8, "Producing/Discharging" 
	elseif producedenergy > 0 and dischargedenergy = 0 and importenergy = 0 then
                return 7, "Discharging"
	elseif producedenergy > 0 and dischargedenergy > 0 and importedenergy > 0 then
                return 6, "Producing/Discharging/Importing" 
	elseif producedenergy > 0 and importedenergy > 0 then
                return 5, "Importing/Producing" 
	elseif producedenergy = 0 and dischargedenergy > 0 and importedenergy > 0 then
                return 4, "Discharging/Importing"
	elseif producedenergy = 0 and dischargedenergy = 0 and importedenergy > 0 then
                return 3, "Importing"
	elseif dischargedenergy > 0 and exportedenergy > 0 then
                return 2, "Discharging/Exporting"
        else
                return 1, "Offline"
	end


end


-- Example usage:
local condition = "Producing/Charging"
local numericalValue = getNumericalValue(condition)

if numericalValue then
    print("Condition:", condition)
    print("Numerical Value:", numericalValue)
else
    print("Condition not found.")
end

