module Constants where
 

import Graphics.SpriteKit
import Convenience
import GameState
 
import Data.Bits
import Data.Word

-- Categorisation of the various items in the physics world.
--
data PhysicsCategory = Block      -- Blocks on the ground
                     | World      -- the ground
                     | Wall       -- left and right wall
                      deriving (Enum)

blocksInRow = 5 :: Int
blocksInCol = 8 :: Int


leftArrowKey  = 123 :: Word16
rightArrowKey = 124 :: Word16

(block1Texture, blockWidth, blockHeight) = defineTexture "blue1.png"
(block2Texture, _,          _) = defineTexture "blue2.png"
(block3Texture, _,          _) = defineTexture "blue3.png"
(block4Texture, _,          _) = defineTexture "blue4.png"
(block5Texture, _,          _) = defineTexture "blue5.png"

blockTextures = [ block1Texture
                , block2Texture
                , block3Texture
                , block4Texture
                , block5Texture] 


-- Velocity constant below which we view a node as resting
--
epsilon :: GFloat
epsilon = 0.0

-- Scene dimensions
--
width, height :: GFloat
width  = fromIntegral blocksInRow * blockWidth
height = fromIntegral blocksInCol * blockHeight

-- Background colour of the sky
--
backgroundColour :: Color
backgroundColour = colorWithRGBA 0.3 0.3 0.3 1.0

categoryBitMask :: [PhysicsCategory] -> Word32
categoryBitMask = foldl setCategoryBit zeroBits
  where
    setCategoryBit bits cat = bits .|. bit (fromEnum cat)

isInCategory :: PhysicsCategory -> Node u -> Bool
isInCategory cat node
  = case nodePhysicsBody node of
      Just body -> testBit (bodyCategoryBitMask body) (fromEnum cat)
      Nothing   -> False

isblock :: Node u -> Bool
isblock node
  = case nodeName node of
      Just "Block" -> True
      _             -> False 

isAnyblock :: ShadesNode -> Bool
isAnyblock node
  = not $ nodeUserData node == NoState


isLanded :: Node u -> Bool
isLanded node
  = case nodeName node of
      Just "Landed"     -> True
      _                 -> False 

isGround :: Node u -> Bool
isGround node
  = case nodeName node of
      Just "Ground"     -> True
      _                 -> False 

isWorld :: Node u -> Bool
isWorld = isInCategory World
