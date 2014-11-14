--[ Functions ]--
function Preech_Bg_OptionsPanel_OnLoad(panel)
    panel.name='Preech Bg';
    panel.okay=Preech_Bg_OptionsPanel_SaveOptions;
    InterfaceOptions_AddCategory(panel);
end

function Preech_Bg_OptionsPanel_ApplyOptions()
    for key, value in pairs(Preech_Bg_DisplayOptions) do
        local checkButton=getglobal('Preech_Bg_OptionsPanel' .. key);
        if (checkButton) then  -- <-- Fixes a bug in case we remove any options
            if (Preech_Bg_DisplayOptions[key]) then
                checkButton:SetChecked(true);
            else
                checkButton:SetChecked(false);
            end
        end
    end
end

function Preech_Bg_OptionsPanel_SaveOptions()
    -- Save the settings
    for key, value in pairs(Preech_Bg_DisplayOptions) do
        local checkButton=getglobal('Preech_Bg_OptionsPanel' .. key);
        if (checkButton and checkButton:GetChecked()) then
            Preech_Bg_DisplayOptions[key]=true;
        else
            Preech_Bg_DisplayOptions[key]=false;
        end
    end
    Preech_Bg_UpdateDisplay();
end
