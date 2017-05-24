module Actions where

import Graphics.SpriteKit
import Constants
import Convenience
import GameState


leftAction :: ShadesNode -> TimeInterval -> ShadesNode
leftAction node _dt 
  = node{nodeActionDirectives = [runCustomActionOn "Block" leftAction']}

leftAction' :: ShadesNode -> TimeInterval -> ShadesNode
leftAction' sprite@Sprite{nodePosition = Point x y}  _dt
  = sprite{nodeActionDirectives = [runAction $ moveTo $ Point ((blockWidth / 2) `max` (x - blockWidth)) y]}


rightAction :: ShadesNode -> TimeInterval -> ShadesNode
rightAction node _dt 
  = node{nodeActionDirectives = [runCustomActionOn "Block" rightAction']}

rightAction' :: ShadesNode -> TimeInterval -> ShadesNode
rightAction' sprite _dt
  = case nodePosition sprite of
      Point x y -> sprite{nodePosition = Point ((width - blockWidth / 2) `min` (x + blockWidth)) y}

