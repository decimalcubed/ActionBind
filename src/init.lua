--!strict

local ActionBind = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

type ActionCallback = (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> ()

type Bind = {
	ActionPriority: number;
	ActionName: string;
	ActionFunction: (...any) -> (...any);
	ActionInputs: {Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions}; --TODO this could be dictionary based
}

local processHooks: {[string]: (input_object: InputObject) -> boolean} = {}
local activateBinds: {Enum.KeyCode} = {}
local binds: {Bind} = {}

local function KeycodeFromPlayerAction(player_action: Enum.PlayerActions)
	
	-- TODO make an implementation of this that is console / mobile compatible, and provides support for AZERTY keyboards
	return if player_action == Enum.PlayerActions.CharacterJump then Enum.KeyCode.Space
		elseif player_action == Enum.PlayerActions.CharacterForward then Enum.KeyCode.W
		elseif player_action == Enum.PlayerActions.CharacterLeft then Enum.KeyCode.A
		elseif player_action == Enum.PlayerActions.CharacterRight then Enum.KeyCode.D
		elseif player_action == Enum.PlayerActions.CharacterBackward then Enum.KeyCode.S
		else Enum.KeyCode.Unknown
end

local function SortBindsByPriority(a: Bind, b: Bind)
	
	return a.ActionPriority < b.ActionPriority
end

local function DoBind(input: InputObject)
	
	local execute_binds: {Bind} = {}
	
	-- Get a list of every bind to run
	for _, binded_action in binds do
		
		if table.find(binded_action.ActionInputs, input.KeyCode) or table.find(binded_action.ActionInputs, input.UserInputType) then

			table.insert(execute_binds, binded_action)
		end
	end
	
	-- Sort every bind by priority --TODO this can msot likely be optimized
	table.sort(execute_binds, SortBindsByPriority)
	
	-- Execute all binds
	for _, binded_action in execute_binds do
		
		binded_action.ActionFunction(binded_action.ActionName, input.UserInputState, input)
	end

	-- Check for activated binds
	if input.UserInputState == Enum.UserInputState.Begin then

		for _, key in activateBinds do

			if input.KeyCode == key then

				--TODO fire :Activate()
			end
		end
	end
end

local function CheckInputHook(input: InputObject)

	-- Check process hooks
	for _, callback in processHooks do

		if callback(input) then

			return true
		end
	end

	return false
end

local function OnInputBegin(input: InputObject, game_processed: boolean)

	if not game_processed or CheckInputHook(input) then

		DoBind(input)
	end
end

local function OnInputEnd(input: InputObject, game_processed: boolean)

	if not game_processed or CheckInputHook(input) then

		DoBind(input)
	end
end

local function OnInputChanged(input: InputObject, game_processed: boolean)

	if not game_processed or CheckInputHook(input) then

		DoBind(input)
	end
end

local function CleanBind(bind: Bind)

	table.clear(bind.ActionInputs)
	table.clear(bind)
end

-- Wraps BindActionAtPriority
function ActionBind.BindAction(action_name: string, callback: ActionCallback, create_touch_button: boolean, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions): Bind

	return ActionBind.BindActionAtPriority(action_name, callback, create_touch_button, math.huge, ...) -- magic number
end

-- Binds an action to a UserInputType or KeyCode at a set priority
function ActionBind.BindActionAtPriority(action_name: string, callback: ActionCallback, create_touch_button: boolean, priority: number, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions): Bind
	
	local bind = {
		ActionPriority = priority;
		ActionName = action_name;
		ActionFunction = callback;
		ActionInputs = {...};
	}
	
	-- Convert playeractions to their respective keycodes. TODO this needs to be redone every time the players input type changes
	for x, input in bind.ActionInputs do
		
		if input.EnumType == Enum.PlayerActions then
			
			bind.ActionInputs[x] = KeycodeFromPlayerAction(input :: any) -- Any cast since the if statement here doesnt actually type refine
		end
	end
	
	table.insert(binds, bind)
	--TODO implement touch button

	return bind
end

-- Unbinds an action, stopping it from being fired
function ActionBind.UnbindAction(action: string | Bind) --TODO add asserts

	if type(action) == "string" then

		for x = #binds, 1, -1 do

			if binds[x].ActionName == action then

				CleanBind(binds[x])
				table.remove(binds, x)
			end
		end
	else

		table.remove(binds, table.find(binds, action))
		CleanBind(action)
	end
end

-- guh
function ActionBind.BindActivate(input_type_to_activate: Enum.UserInputType, ...: Enum.KeyCode)

	for _, key in {...} do

		table.insert(activateBinds, key)
	end
end

function ActionBind.UnbindActivate(input_type_to_activate: Enum.UserInputType, key: Enum.KeyCode)

	local index = table.find(activateBinds, key)
	if index then

		table.remove(activateBinds, index)
	end
end

-- Hooking system for custom gameprocessed implementations
function ActionBind.RegisterProcessHook(tag: string, callback: (input_object: InputObject) -> boolean)

	processHooks[tag] = callback
end

-- Unregisters a hook
function ActionBind.DeregisterProcessHook(tag: string)

	processHooks[tag] = nil
end

--[[
-- Example process hook that blocks all inputs that are not in the Begin state
ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject)
	
	return input_object.UserInputState ~= Enum.UserInputState.Begin
end)
]]

UserInputService.InputChanged:Connect(OnInputChanged)
UserInputService.InputBegan:Connect(OnInputChanged)
UserInputService.InputEnded:Connect(OnInputChanged)

return ActionBind
