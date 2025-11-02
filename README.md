# 🚏 Godot EventBus

A lightweight, plug-and-play **Event Bus** system for **Godot 4.x** that lets your nodes communicate **without hard references or tangled signal connections**.
It’s built for modular, decoupled game architecture — perfect for UI, gameplay systems, managers, and tools that need to talk to each other cleanly.

---

## ✨ Features

* 🔌 **Subscribe / Unsubscribe** dynamically at runtime
* 📨 **Publish events globally** from anywhere — no node references needed
* 🧱 **Clean decoupling** between systems (UI ↔ Gameplay ↔ Audio, etc.)
* 🔍 Optional **debug logging** to trace event flow
* 💡 Works seamlessly with autoloads or scene-based setups

---

## 📦 Installation

1. Copy **`EventBus.gd`** into your project (recommended path: `res://addons/eventbus/EventBus.gd`)
2. Add it as an **autoload singleton**:

   * In **Project → Project Settings → Autoload**, add the script and name it `EventBus`
3. Click **Add** — you’re ready to go!

---

## 🧠 Usage

### ▶️ Subscribing to Events

```gdscript
# Subscribe to a named event
EventBus.subscribe(&"player_damaged", Callable(self, "_on_player_damaged"))

func _on_player_damaged(amount: int) -> void:
	print("Player took", amount, "damage")
```

---

### 📣 Publishing Events

```gdscript
# Emit an event to all subscribers
EventBus.publish(&"player_damaged", 10)
```

---

### 🚫 Unsubscribing

```gdscript
EventBus.unsubscribe(&"player_damaged", Callable(self, "_on_player_damaged"))
```

---

### ⚙️ Example: Gameplay → UI

**Player.gd**

```gdscript
func take_damage(amount: int) -> void:
	EventBus.publish(&"player_damaged", amount)
```

**UIHealthBar.gd**

```gdscript
func _ready() -> void:
	EventBus.subscribe(&"player_damaged", Callable(self, "_on_player_damaged"))

func _on_player_damaged(amount: int) -> void:
	health -= amount
	update_bar()
```

Now your UI updates automatically without referencing the player node directly.

---

## 🧩 API Reference

### `subscribe(event: StringName, method: Callable) -> void`

Subscribes a listener to an event so it’s notified whenever that event is published.

### `unsubscribe(event: StringName, method: Callable) -> void`

Removes a previously subscribed listener.

### `publish(event: StringName, ...args) -> void`

Fires the event and sends arguments to all subscribers.

### `_debug_enabled: bool`

If true, logs all SUB / PUB actions in the output console.

---

## 💬 Why Use EventBus Instead of Built-In Signals?

| Method              | Pros                                | Cons                               |
| ------------------- | ----------------------------------- | ---------------------------------- |
| **Signals**         | Great for direct node relationships | Break easily if scene tree changes |
| **Hard References** | Simple for small projects           | Tight coupling, hard to reuse      |
| **EventBus**        | Fully decoupled, easy to scale      | Slightly less traceable            |

> Use signals for local communication, and EventBus for global systems and managers.

---

## 🧑‍💻 Contributing

Pull requests and feedback are welcome!
If you find a bug or want a feature added (like event priorities or once-only listeners), open an issue or PR.

---

## ⚖️ License

MIT License — free for commercial and personal use.
Attribution appreciated but not required. ❤️

---

Would you like me to include a **short “How It Works” diagram** (ASCII or image-ready Markdown) that shows how events flow from publisher → EventBus → subscribers? It’s great for GitHub landing pages.
