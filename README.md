# ActionBind
A wrapper for [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService), designed to replace and improve upon [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService), offering similar usage to allow for smooth replacement.

# About
ActionBind is currently not finished, and may have issues. It also does not contain every method that ContextActionService does, though most will be added when needed.

ActionBind is designed to be a drag-and-drop replacement for [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService), requiring minimal syntax changes.
As such, the documentation at [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService) can be used in place of ActionBind's own documentation, as it provides more concise descriptions.

---

### Feature: Process hook

A process hook is used to grant developers control over which inputs are ignored similar to GameProcessed.
When an input is processed, if it passes the GameProcessed check, a Process hook check is ran, if any of these hooks return true, the input is ignored similarly to GameProcessed.

  - **Type**
  
    ```lua
    type ProcessHook = (input_object: InputObject, was_queued: boolean) -> boolean;
    ```

  - **Usage**

    ```lua
    -- Example process hook that blocks all inputs that are not in the Begin state that were also queued
    ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject, was_queued: boolean)
      return input_object.UserInputState ~= Enum.UserInputState.Begin and was_queued
    end)
    ```
---

### Feature: Queue hooks

A queue hook is a feature designed to simplify input queuing for developers in a performant way.
When an input is processed, if it passes all process checks, a Queue hook check is ran, if any of these hooks return true, the input will be ignored and put into the hooks queue.
When a queue is triggered, it runs a QueueTrigger callback (if any is passed) on every input, if the trigger returns true, the input will be ignored.

  - **Type**
  
    ```lua
    type QueueHook = (input_object: InputObject) -> boolean;
    ```
    ```lua
    type QueueTrigger = (input_object: InputObject, time_queued: number) -> boolean;
    ```
    
  - **Usage**

    ```lua
    -- Example queue hook that queues all jump inputs when the player is in the air
    ActionBind.RegisterQueueHook("ExampleQueue", function(input_object: InputObject)
      return input_object.KeyCode == Enum.KeyCode.Space and player_in_air
    end)

    -- Trigger the example queue, but only trigger binds that were executed less than 100ms ago
    ActionBind.TriggerQueue("ExampleQueue", function(input_object: InputObject, queued_time: number)
      return os.clock() - queued_time > 0.1
    end)
    ```
---


### Type: BindCallback

Callback functions that are passed into BindAction and BindActionAtPriority, the usage for this is the exact same as its usage in [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService),
this is just here to provide a type that is used in other functions.
Bound callbacks will only be ran when gameprocessed is false, and all registered process hooks return false.

  - **Type**
  
    ```lua
    type ActionCallback = (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> ()
    ```
    
  - **Usage**

    ```lua
    -- Example process hook that blocks all inputs that are not in the Begin state that were also queued
    ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject, was_queued: boolean)
      return input_object.UserInputState ~= Enum.UserInputState.Begin and was_queued
    end)
    ```
---

### Type: Bind

A Bind is an object unique to ActionBind, Binds are used internally but are exposed to developers for numerous reasons.
Binds can be modified after binding to change the keybinds of actions, without re-binding them, allowing for greater quality of life.
Binds can also be used in place of the action name in UnbindAction, which is faster and in some cases where you have multiple actions bound with the same name, it is also preferable.

  - **Type**
  
    ```lua
    type Bind = {
    	ActionPriority: number;
    	ActionName: string;
    	ActionFunction: (...any) -> (...any);
    	ActionInputs: {Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions};
    }
    ```
---

### RegisterProcessHook()

Registers a process hook.
Currently process hooks are not objects, and registering multiple hooks with the same tag will simply overwrite them. This behavior may change, but syntax and usage will remain the same.

  - **Type**
  
    ```lua
    function ActionBind.RegisterProcessHook(tag: string, callback: (input_object: InputObject) -> boolean)
    ```

  - **Usage**

    ```lua
    -- Example process hook that blocks all inputs that are not in the Begin state
    ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject)
	    return input_object.UserInputState ~= Enum.UserInputState.Begin
    end)
    ```
---

### DeregisterProcessHook()

Deregisters a proccess hook.

  - **Type**
  
    ```lua
    function ActionBind.DeregisterProcessHook(tag: string)
    ```

  - **Usage**

    ```lua
    ActionBind.DeregisterProcessHook("ExampleHook")
    ```
---

### SimulateInput()

Simulates an input, running it through input hooks.

  - **Type**
  
    ```lua
    function ActionBind.SimulateInput(delta: Vector3, keycode: Enum.KeyCode, position: Vector3, input_state: Enum.UserInputState, input_type: Enum.UserInputType)
    ```

  - **Usage**

    ```lua
    ActionBind.SimulateInput(Vector3.zero, Enum.KeyCode.Space, Vector3.zero, Enum.UserInputState.Begin, Enum.UserInputType.Keyboard)
    ```
---

### BindActionAtPriority()

Binds a callback to all passed through inputs at a specific priority, the callback will be ran in order of lowest-highest priority. Returns a Bind
Callbacks only run when gameprocessed and all registered process hooks are false.

  - **Type**

    ```lua
    function ActionBind.BindActionAtPriority(action_name: string, callback: BindCallback, create_touch_button: boolean, priority: number, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions)
    ```

  - **Usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindActionAtPriority) for usage.
---

### BindAction()

Binds a callback to all passed through inputs. This function wraps BindActionAtPriority internally. Returns a Bind
Callbacks only run when gameprocessed and all registered process hooks are false.

  - **Type**

    ```lua
    function ActionBind.BindAction(action_name: string, callback: BindCallback, create_touch_button: boolean, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions)
    ```

  - **Usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindAction) for usage.
---

### UnbindAction()

Unbinds an action, clearing it from memory and preventing its callback from running again.
When passing a string, it will unbind every action which has a matching name.

  - **Type**

    ```lua
    function ActionBind.UnbindAction(action: string | Bind)
    ```

  - **Usage**

    ```lua
    local bind = ActionBind.BindAction("Example", print, false, Enum.KeyCode.F)
    
    ActionBind.UnbindAction(bind)
    -- Or
    ActionBind.UnbindAction("Example")
    ```
---

### BindActivate()

Binds tool activation to a keycode, Whenever a bound key is pressed, the :Activate() method will be called on the players currently equipped tool (If one exists)

  - **Type**

    ```lua
    function ActionBind.BindActivate(input_type_to_activate: Enum.UserInputType, ...: Enum.KeyCode)
    ```

  - **Usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindActivate) for usage.
---

### UnbindActivate()

Unbinds a keycode from tool activation.

  - **Type**

    ```lua
    function ActionBind.UnbindActivate(input_type_to_activate: Enum.UserInputType, key: Enum.KeyCode)
    ```

  - **Usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#UnbindActivate) for usage.
