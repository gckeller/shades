# A Shades clone in Haskell with SpriteKit

![Shades Loop](https://raw.githubusercontent.com/gckeller/shades/master/images/ShadesLoop.gif)

Shades is a sample game for the [Haskell SpriteKit binding](https://github.com/mchakravarty/HaskellSpriteKit). It also serves as a running example in the paper [Haskell SpriteKit — Transforming an Imperative Object-oriented API into a Purely Functional One](http://www.cse.unsw.edu.au/~chak/papers/CK17.html).

## Building Shades as a standalone Mac app

The repo includes a subdirectory `ShadesApp` with an Xcode project that includes a simple Swift wrapper, which turns the Haskell for Mac SpriteKit project into a standalone Mac app. The Xcode project contains two custom build phases running the shell scripts `BuildHaskell.sh` and `CopyHaskellDynlibs.sh`, which compile the Haskell code into a dynamic library and copy all dependencies, respectively. Moreover, `ViewController.swift` loads the Haskell scene and presents it in an `SKView`.
