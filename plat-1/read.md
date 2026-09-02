# Game Design Document

## 1. Overview

### 1.1 Story
There is a prince who desires to ascend the throne and become the king. However, the current king deems him unworthy of the crown. To prove his worth and claim his birthright, the prince is given a monumental challenge: he must enter the fighting pit and defeat a terrifying monster. 

### 1.2 Core Gameplay Concept
The game offers a unique risk-reward structure. The player can choose to fight the monster in the pit immediately from the start of the game. If they manage to defeat it, they beat the game. However, this immediate fight is designed to be extremely difficult. 

To gain a significant advantage, the player can choose to delay the fight and instead embark on a journey. This journey is a platforming-focused adventure where the player hunts for **Whetstones** and **Health Potions** to prepare for the ultimate battle. 

Additionally, the game features a **Karma System** that tracks the player's actions, which will directly affect the dynamics of the final fight with the monster.

---

## 2. Gameplay Mechanics

### 2.1 The Fighting Pit (Boss Fight)
- **Immediate Access:** The fighting pit is accessible right from the beginning.
- **High Difficulty:** The monster is incredibly strong, making an unprepared fight a massive challenge.
- **The Ultimate Goal:** Defeating the monster is the win condition of the game.

### 2.2 The Journey (Platforming Adventure)
- **Core Loop:** If the player chooses to prepare, they will navigate through various levels (like the Whetstone Hunt). This section relies heavily on platforming skills—jumping, dodging, and exploring.
- **Resource Gathering:** The main objective of the journey is to find items that provide a statistical or tactical advantage against the monster.

### 2.3 Karma System
- **Function:** The player's actions and decisions during the journey accumulate Karma.
- **Impact:** Karma directly affects the final boss fight. Good or bad Karma might alter the monster's strength, its attack patterns, or the environment of the fighting pit itself, making the player's moral choices mechanically significant.

---

## 3. Game Components & Items

### 3.1 The Prince (Player Character)
- **Role:** The protagonist controlled by the player.
- **Abilities:** Platforming movement (run, jump, etc.), attacking, and using items from the inventory.

### 3.2 The Monster (Final Boss)
- **Role:** The ultimate test of the prince's worth.
- **Function:** A complex boss enemy with high stats. Its behavior and difficulty are directly influenced by the player's collected Karma and preparation level.

### 3.3 Whetstone
- **Function:** A crucial upgrade item scattered throughout the platforming journey.
- **Effect:** Collecting Whetstones increases the sharpness and damage output of the Prince's weapon, making the monster fight significantly more manageable.

### 3.4 Health Potion
- **Function:** A consumable item found during the journey and stored in the inventory UI.
- **Effect:** Restores the Prince's health points (HP). Having a stock of Health Potions allows the player to survive longer against the monster's devastating attacks.

### 3.5 The Environment
- **Function:** Consists of platforming challenges, hazards, and potential smaller enemies that the player must overcome to collect Whetstones and Health Potions.

---

## 4. Credits

**Developed by:** [Placeholder - Lead Developer/Team Name]
**Club:** vertex GDNA

**Art Assets:** [Placeholder - Artist Name / Asset Pack Source]
**Music & Sound Effects:** [Placeholder - Composer Name / Audio Source]
**Programming:** [Placeholder - Programmer Name]
**Additional Design:** [Placeholder - Designer Name]
**Engine:** Godot Engine

*(Note: Replace placeholders with actual names and sources before publishing)*
