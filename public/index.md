+++
title="Tidy Towers"

[extra]
team="Sparsh Sanchorawala"
thumbnail="thumbnail.png"
+++

# Rules

## Introduction
You are given a tower consisting of identical cubes, each of which has the same colors on the vertical sides in the same clockwise order. The goal is for all cubes to be aligned in that all colors are the same vertically. A tower with such an alignment is called _tidy_. 

Two kinds of operations are allowed: 

- rotate a cube _c<sub>1</sub>_ and then all cubes above it rotate as well
- rotate a cube _c<sub>1</sub>_ and hold a cube _c<sub>2</sub>_ above _c<sub>1</sub>_ so that all cubes starting with _c<sub>1</sub>_ and up to the cube just below _c<sub>2</sub>_ rotate

If a rotation takes place, _c<sub>1</sub>_ is said to be touched and rotated.


## Single Player
Given the initial state of the tower, your goal is to make it tidy using the minimum number of rotations possible.

## Two Player
You and your opponent take turns making rotations on the tower. The same operations are allowed except that neither player is allowed to rotate a block that either player has already both touched and rotated (even if that rotation is a complete rotation that does not change the orientation of the block). The number of moves per player is an additional parameter.

The score of a tower is how close it is to being tidy. Each player starts with a score of 0. If a player rotates to a tower, and the score of that tower is higher than their score, the player's score is updated to that score. 

The player with the highest score at the end of the game wins. In case of ties, the player to achieve this score first wins. If one of the player makes a tidy tower, the game ends with that player being the winner.
