+++
title="Tidy Towers"

[extra]
team="Sparsh Sanchorawala"
thumbnail="thumbnail.png"
+++

# Rules

## Introduction
You are given a tower consisting of identical cubes, each of which has the same colors on the vertical sides in the same clockwise order. The goal is for all cubes to be aligned in that all colors are the same vertically. A tower with such an alignment is called _tidy_. 

Two kinds of operations are allowed: rotate a cube and then all cubes above it rotate as well or rotate a cube _c<sub>1</sub>_ and hold a cube _c<sub>2</sub>_ above _c<sub>1</sub>_ so that neither cube _c<sub>2</sub>_ nor the cubes above _c<sub>2</sub>_ rotate but all cubes starting with _c<sub>1</sub>_ and up to the cube just below _c<sub>2</sub>_ rotate. If a rotation takes place, _c<sub>1</sub>_ is said to be touched and rotated.

See [here](https://dl.acm.org/doi/pdf/10.1145/3614559) for more.

## Single Player
Given the initial state of the tower, your goal is to make it tidy using the minimum number of rotations possible.

## Two Player
You and your opponent take turns making rotations on the tower. The same operations are allowed except that neither player is allowed to rotate a block that either player has already both touched and rotated (even if that rotation is a complete rotation that does not change the orientation of the block). The number of moves per player is an additional parameter.

At any point, a tower is said to be _k_-tidy if all but _k_ of its blocks are tidy i.e. all but _k_ of its blocks have the same orientation.
Let _min_ be the smallest _k_ for which either player creates a _k_-tidy tower over the course of the game.
The first player to form a _min_-tidy tower wins the game.
If one of the player makes a _0_-tidy tower, the game ends with that player being the winner.
