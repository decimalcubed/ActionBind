# ActionBind
A wrapper for [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService), designed to replace and improve upon [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService), offering similar usage to allow for smooth replacement.

# About
ActionBind is currently not finished, and may have issues. It also does not contain every method that ContextActionService does, though most will be added when needed.

ActionBind is designed to be a drag-and-drop replacement for [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService), requiring minimal syntax changes.
As such, the documentation at [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService) can be used in place of ActionBind's own documentation, as it provides more concise descriptions.

### Feature: Process hook

A process hook is used to grant developers control over which inputs are ignored similar to GameProcessed.
When an input is processed, if it passes the GameProcessed check, a Process hook check is ran, if any of these hooks return true, the input is ignored similarly to GameProcessed.

  - **type**
    
    ```lua
    function ActionBind.ProcessHook(input_object: InputObject) -> boolean)
    ```

  - **usage**

    ```lua
    -- Example process hook that blocks all inputs that are not in the Begin state
    ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject)
      return input_object.UserInputState ~= Enum.UserInputState.Begin
    end)
    ```
---

### Type: BindCallback

Callback functions that are passed into BindAction and BindActionAtPriority, the usage for this is the exact same as its usage in [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService),
this is just here to provide a type that is used in other functions.
Bound callbacks will only be ran when gameprocessed is false, and all registered process hooks return false.

  - **type**
  
    ```lua
    type ActionCallback = (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> ()
    ```
---

### Type: Bind

A Bind is an object unique to ActionBind, Binds are used internally but are exposed to developers for numerous reasons.
Binds can be modified after binding to change the keybinds of actions, without re-binding them, allowing for greater quality of life.
Binds can also be used in place of the action name in UnbindAction, which is faster and in some cases where you have multiple actions bound with the same name, it is also preferable.

  - **type**
  
    ```lua
    type ActionCallback = (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> ()
    ```

  - **usage**

    ```lua
    local function Callback(action_name: string, input_state: Enum.UserInputState, input_object: InputObject)

      if action_name == "Jump" and input_state == Enum.UserInputState.Begin then

        print("Jump")
      end
    end
    ```
---

### RegisterProcessHook()

Registers a process hook.
Currently process hooks are not objects, and registering multiple hooks with the same tag will simply overwrite them. This behavior may change, but syntax and usage will remain the same.

  - **type**
  
    ```lua
    function ActionBind.RegisterProcessHook(tag: string, callback: (input_object: InputObject) -> boolean)
    ```

  - **usage**

    ```lua
    -- Example process hook that blocks all inputs that are not in the Begin state
    ActionBind.RegisterProcessHook("ExampleHook", function(input_object: InputObject)
	    return input_object.UserInputState ~= Enum.UserInputState.Begin
    end)
    ```
---

### DeregisterProcessHook()

Deregisters a process hook.

  - **type**
  
    ```lua
    function ActionBind.DeregisterProcessHook(tag: string)
    ```

  - **usage**

    ```lua
    ActionBind.DeregisterProcessHook("ExampleHook")
    ```
---

### BindActionAtPriority()

Binds a callback to all passed through inputs at a specific priority, the callback will be ran in order of lowest-highest priority. Returns a Bind
Callbacks only run when gameprocessed and all registered process hooks are false.

  - **Type**

    ```lua
    function ActionBind.BindActionAtPriority(action_name: string, callback: BindCallback, create_touch_button: boolean, priority: number, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions)
    ```

  - **usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindActionAtPriority) for usage.
---

### BindAction()

Binds a callback to all passed through inputs. This function wraps BindActionAtPriority internally. Returns a Bind
Callbacks only run when gameprocessed and all registered process hooks are false.

  - **Type**

    ```lua
    function ActionBind.BindAction(action_name: string, callback: BindCallback, create_touch_button: boolean, ...: Enum.KeyCode | Enum.UserInputType | Enum.PlayerActions)
    ```

  - **usage**

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

  - **usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindActivate) for usage.
---

### UnbindActivate()

Unbinds a keycode from tool activation.

  - **Type**

    ```lua
    function ActionBind.UnbindActivate(input_type_to_activate: Enum.UserInputType, key: Enum.KeyCode)
    ```

  - **usage**

    See [Roblox documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#UnbindActivate) for usage.
