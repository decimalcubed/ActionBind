--!strict

local ActionBind = {}

local PlayersService = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local runtimeServer = game:GetService("RunService"):IsServer()

export type ActionCallback = (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> ()

export type ProcessHook = (input_object: InputObject, was_queued: boolean) -> boolean;
export type QueueHook = (input_object: InputObject) -> boolean;
export type QueueTrigger = (input_object: InputObject, time_triggered: number) -> boolean;

export type Bind = {
	ActionPriority: number;
	ActionName: string;
	ActionFunction: (...any) -> (...any);
	ActionInputs: {Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions};
}

local processHooks: {[string]: ProcessHook} = {}

local queueHooks: {[string]: QueueHook} = {}
local queueInputs: {[string]: {InputObject}} = {}
local queueInputTimes: {[string]: {number}} = {}

local activateBinds: {Enum.KeyCode} = {}
local binds: {Bind} = {}
local bindButtonGuidMap: {[Bind]: string} = {} -- This isnt put in the bind itself since then people can mess with it and cause issues
local localPlayer = PlayersService.LocalPlayer

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

local function DoBind(input: InputObject, bypass_queue: boolean)
	
	-- Check queue hooks
	if not bypass_queue then
		
		for queue, hook in queueHooks do

			if hook(input) then
				
				local fake_input: InputObject = table.freeze({

					Delta = input.Delta;
					KeyCode = input.KeyCode;
					Position = input.Position;
					UserInputState = input.UserInputState;
					UserInputType = input.UserInputType;
				}) :: any -- The input has to be recreated so that the input state doesnt change
				
				local id = #queueInputs[queue] + 1
				queueInputs[queue][id] = fake_input
				queueInputTimes[queue][id] = os.clock()

				return
			end
		end
	end

	local execute_binds: {Bind} = {}

	-- Get a list of every bind to run
	for _, binded_action in binds do

		if table.find(binded_action.ActionInputs, input.KeyCode) or table.find(binded_action.ActionInputs, input.UserInputType) then

			table.insert(execute_binds, binded_action)
		end
	end

	-- Sort every bind by priority --TODO this can most likely be optimized
	table.sort(execute_binds, SortBindsByPriority)

	-- Execute all binds
	for _, binded_action in execute_binds do

		binded_action.ActionFunction(binded_action.ActionName, input.UserInputState, input)
	end

	-- Check for activated binds
	local character = localPlayer.Character
	if character and input.UserInputState == Enum.UserInputState.Begin then
		
		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool then
			
			for _, key in activateBinds do

				if input.KeyCode == key then

					tool:Activate()
				end
			end
		end
	end
end

local function CheckInputHook(input: InputObject, was_queued: boolean)

	-- Check process hooks
	for _, callback in processHooks do

		if callback(input, was_queued) then

			return true
		end
	end

	return false
end

local function OnInputBegin(input: InputObject, game_processed: boolean)

	if not (game_processed or CheckInputHook(input, false)) then

		DoBind(input, false)
	end
end

local function OnInputEnd(input: InputObject, game_processed: boolean)

	if not (game_processed or CheckInputHook(input, false)) then

		DoBind(input, false)
	end
end

local function OnInputChanged(input: InputObject, game_processed: boolean)

	if not (game_processed or CheckInputHook(input, false)) then

		DoBind(input, false)
	end
end

local function CleanBind(bind: Bind)
	
	if bindButtonGuidMap[bind] then
		
		local button_guid = bindButtonGuidMap[bind]
		bindButtonGuidMap[bind] = nil
		
		ContextActionService:UnbindAction(button_guid)
	end

	table.clear(bind.ActionInputs)
	table.clear(bind)
	table.freeze(bind)
end

local function ButtonCallback(guid: string, input_state: Enum.UserInputState, input_object: InputObject)
	
	DoBind(input_object, false)
end

-- Wraps BindActionAtPriority
function ActionBind.BindAction(action_name: string, callback: ActionCallback, create_touch_button: boolean, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions): Bind

	return ActionBind.BindActionAtPriority(action_name, callback, create_touch_button, math.huge, ...)
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
	
	if create_touch_button then
		
		local button_guid = `{HttpService:GenerateGUID(false)}{action_name}`
		bindButtonGuidMap[bind] = button_guid
		
		ContextActionService:BindAction(button_guid, ButtonCallback, true)
	end

	return bind
end

-- Unbinds an action, stopping it from being fired
function ActionBind.UnbindAction(action: string | Bind)

	if type(action) == "string" then

		for x = #binds, 1, -1 do

			if binds[x].ActionName == action then

				CleanBind(binds[x])
				table.remove(binds, x)
			end
		end
	else
		
		local bind = assert(table.find(binds, action), "Invalid bind")
		table.remove(binds, bind)
		CleanBind(action)
	end
end

-- Unbinds all actions
function ActionBind.UnbindAllActions()

	for _, bind in binds do
		
		CleanBind(bind)
	end
	
	table.clear(binds)
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

-- Registers a ho
function ActionBind.RegisterProcessHook(tag: string, callback: ProcessHook)

	processHooks[tag] = callback
end

-- Unregisters a hook
function ActionBind.DeregisterProcessHook(tag: string)

	processHooks[tag] = nil
end

-- Simulates an input as if a player had actually done the input, is still affected by input hooks --TODO make this so they can bypass the queue and hooks
function ActionBind.SimulateInput(delta: Vector3, keycode: Enum.KeyCode, position: Vector3, input_state: Enum.UserInputState, input_type: Enum.UserInputType)
	
	local fake_input: InputObject = table.freeze({
		
		Delta = delta;
		KeyCode = keycode;
		Position = position;
		UserInputState = input_state;
		UserInputType = input_type;
	}) :: any
	
	if not CheckInputHook(fake_input, false) then

		DoBind(fake_input, false)
	end
end

-- Hooking system for queues
function ActionBind.RegisterQueueHook(tag: string, callback: QueueHook)

	queueHooks[tag] = callback
	queueInputs[tag] = {}
	queueInputTimes[tag] = {}
end

function ActionBind.TriggerQueue(tag: string, queue_trigger: QueueTrigger?)
	
	assert(queueInputs[tag], `Queue {tag} does not exist`)
	
	local queue_inputs = queueInputs[tag]
	local queue_times = queueInputTimes[tag]
	
	for x, input in queue_inputs do
		
		local trigger_true = if queue_trigger then queue_trigger(input, queue_times[x]) else true
		queue_inputs[x] = nil
		queue_times[x] = nil
		
		if trigger_true or CheckInputHook(input, true) then
			
			continue
		end
		
		DoBind(input, true)
	end
end

-- Unregisters a queue hook
function ActionBind.DeregisterQueueHook(tag: string)

	queueHooks[tag] = nil
	queueInputs[tag] = nil
	queueInputTimes[tag] = nil
end

-- Button wrapper gurger stuff


--[[
-- Example process hook that blocks all inputs that are not in the Begin state
ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject)
	
	return input_object.UserInputState ~= Enum.UserInputState.Begin
end)
]]

if not runtimeServer then
	
	UserInputService.InputChanged:Connect(OnInputChanged)
	UserInputService.InputBegan:Connect(OnInputChanged)
	UserInputService.InputEnded:Connect(OnInputChanged)
end

return ActionBind
