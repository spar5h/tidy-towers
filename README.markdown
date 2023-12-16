# Tidy Towers Game for the Dr Ecco Heuristic Problem Solving Website

![thumbnail](public/thumbnail.png)

# Developing

Make sure you have [Elm](https://elm-lang.org/) and [`create-elm-app`](https://github.com/halfzebra/create-elm-app) installed. 

First, clone this repo:

```
git clone https://github.com/spar5h/tidy-towers
```

To run the development server inside the repository:

```
elm-app start
```

To build the application, run the build script from inside the repository (make sure you have execution permissions):

```
./build.sh
```

# Directory Structure

Within the root directory of this project:
1. `elm.json` contains information used by Elm (e.g. dependencies). Don't modify this file directly. 
2. `build.sh` is the script used to build a production build ready for deployment to the Dr Ecco website. This replaces the build folder with a new build.  
3. The `src` directory contains all the actual game code. 
4. The `public` directory contains assets that are copied directly to the final production build. 
5. The `tests` directory contains tests for the Elm code.
6. The `elm-stuff` directory (ignored by Git) contains Elm dependencies. Don't modify this folder directly. 
7. The `build` directory (ignored by Git) contains the production build produced by `build.sh`.

Within the `src` folder, there are five Elm files in this project:
1. `src/Main.elm` is the entrypoint that handles delegating to the Settings and Game screen views. 
2. `src/Common.elm` contains basic utility types and functions shared by both `Settings.elm` and `Game.elm`.
3. `src/Settings.elm` contains the model, view and update for the Settings screen. 
4. `src/Game.elm` contains the model, view and update for the Gameplay screen (including all the game logic). 
5. `src/index.js` contains the JavaScript entrypoint for the live development server. This file is not used for the production build.
6. `src/main.css` contains all the CSS styling.

Within the `public` folder, there are three essential static assets:
1. `public/index.html` contains the HTML entrypoint that is used by both the live development server and the production build. 
2. `public/index.md` is a Markdown file that gets converted to the information page for your game. 
3. `public/thumbnail.png` is a square image used as a thumbnail.

# References

Original Game: [Tidy Towers](https://dl.acm.org/doi/pdf/10.1145/3614559)

Template for the entire game: [Gomoku](https://github.com/wjmn/gomoku)

Random Tower Generation by Seed: [Effective Eavesdropping](https://github.com/wjmn/effective-eavesdropping)

Rotating Cubes in CSS: [https://codepen.io/Codeible/pen/wveKQqE](https://codepen.io/Codeible/pen/wveKQqE)
