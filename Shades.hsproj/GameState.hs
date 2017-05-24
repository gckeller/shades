module GameState where
  
import Graphics.SpriteKit
import Random
import Data.Map.Strict

data NodeState = NoState
               | NodeCol NodeColour
               deriving (Eq, Show)
               
data NodeColour 
  = LightBlue
  | SkyBlue
  | MediumBlue
  | Blue
  | NightBlue
  deriving (Eq, Enum, Bounded, Show)
               
type ShadesNode = Node NodeState


darkerShade :: NodeState -> NodeColour
darkerShade (NodeCol col)
  | col == maxBound = col
  | otherwise       = succ col
darkerShade st      = error "darkerShade"

randomColour :: ShadesScene -> (ShadesScene, NodeColour)
randomColour scene = (scene{sceneData = ss'}, colour)
 where
   maxColour :: NodeColour
   maxColour = maxBound

   colour   = toEnum (i `mod` (1 + fromEnum maxColour))   
   (i : is) =  randomInts (sceneData scene)
   ss'      = (sceneData scene){randomInts = is}

data GameState = Running 
               | Landed
               | GameOver
               deriving (Eq, Show)

data SceneState = SceneState 
                  { sceneScore   :: Int
                  , leftPressed  :: Bool
                  , rightPressed :: Bool
                  , bumpScore    :: Maybe Int
                  , gameState    :: GameState
                  , randomInts   :: [Int] 
                  }

initialSceneState 
  = SceneState 
    { sceneScore   = 0
    , leftPressed  = False 
    , rightPressed = False     
    , bumpScore    = Nothing
    , gameState    = Running
    , randomInts   = randomNums
    }

type ShadesScene = Scene SceneState NodeState
