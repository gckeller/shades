{-# LANGUAGE NamedFieldPuns, RecordWildCards #-}

import Graphics.SpriteKit

import Actions
import Constants
import Convenience
import GameState
import Random

import Data.List

shades :: ShadesScene   
shades
  = spawnNewblock $ (sceneWithSize (Size width height))
    { sceneBackgroundColor  = backgroundColour
    , sceneChildren         = [blocks, walls, score]
    , sceneData             = initialSceneState
    , sceneUpdate           = Just update
    , scenePhysicsWorld     = physicsWorld
                              { worldGravity         = Vector 0 (-5)
                              , worldContactDidBegin = Just contact
                              }
    , sceneHandleEvent      = Just handleEvent
    }

update :: ShadesScene -> TimeInterval -> ShadesScene
update scene@Scene{ sceneData = sceneState@SceneState{..} } _dt 
  = case gameState of
      Running 
        | leftPressed          -> blockLeft     scene{ sceneData = sceneState{ leftPressed  = False } }
        | rightPressed         -> blockRight    scene{ sceneData = sceneState{ rightPressed = False } }
        | Just n  <- bumpScore -> updateScore n scene{ sceneData = sceneState{ bumpScore =  Nothing } }
        | otherwise            -> scene 
      Landed                   -> if sceneResting scene then resting scene else scene
      GameOver                 -> gameOver scene
      
gameOver :: ShadesScene -> ShadesScene
gameOver scene@Scene{ sceneData = sceneState } 
  = scene{ sceneActionDirectives = [runCustomActionOn "Score" gameOverScore] 
         , sceneChildren         = gameOverNotice : sceneChildren scene
         }
  where
    gameOverScore node _ = node{labelText = "Final Score " ++ show (sceneScore sceneState)}

-- update score display
--
updateScore :: Int -> ShadesScene -> ShadesScene 
updateScore n scene@Scene{ sceneData = sceneState }
  = let
      scene' = scene{ sceneData = sceneState{ sceneScore = newScore, bumpScore =  Nothing} }
    in
      addSceneActionDirective scene' $ runCustomActionOn "Score" setScore

  where
    newScore = sceneScore sceneState + n
    setScore label@Label{} _dt = label{ labelText = show newScore }


bumpScoreCnt :: Int -> SceneState -> SceneState                             
bumpScoreCnt cnt scene 
  = case bumpScore scene of
      Nothing -> scene {bumpScore = Just cnt}
      Just n  -> scene {bumpScore = Just (n + cnt)}

resting :: ShadesScene -> ShadesScene
resting scene
  = case removeColouredRow scene of
      Nothing      -> if row < blocksInCol - 1
                      then spawnNewblock scene
                      else scene { sceneData = (sceneData scene){ gameState = GameOver}}
      Just blocks  -> scene { sceneData = bumpRowScore $ sceneData scene
                            , sceneActionDirectives 
                                        = [ runCustomActionOn "Blocks" (setNodeChildren blocks)]                                          
                            }
  where

   -- return Nothing if no row of same colour can be found
   -- otherwise, return list of blocks without that row
   removeColouredRow :: ShadesScene -> Maybe [ShadesNode]
   removeColouredRow scene 
     | len == blocksInRow 
     = Just $ filter (\b -> (getRow b) /= row) (nodeChildren $ head $ sceneChildren scene)
     | otherwise          
     = Nothing
     
   blocks = sortOn getRow $ nodeChildren $ head $ sceneChildren scene -- relies on stable pos of children
   (len, _, row) = foldl findRow (0, NoState, 0) blocks
   findRow (currLen, col, row) block
     | currLen == blocksInRow             = (currLen, col, row)
     | col == blockCol && row == blockRow = (currLen + 1, col, row)
     | otherwise                          = (1, blockCol, blockRow)
     where
       blockRow = getRow block
       blockCol = nodeUserData block

   bumpRowScore = bumpScoreCnt 100
   
   setNodeChildren :: [ShadesNode] -> ShadesNode -> TimeInterval -> ShadesNode
   setNodeChildren newKids node _dt = node{nodeChildren = newKids}


spawnNewblock :: ShadesScene -> ShadesScene
spawnNewblock scene 
  = sceneLanded{ sceneChildren = addB (sceneChildren sceneLanded)
               , sceneData     = sceneState{ gameState = Running }}   
   -- TODO: why doesn't this work???
   -- sceneLanded{ sceneActionDirectives = [runCustomActionOn "Blocks" addNewBlock]
   --             , sceneData = sceneState { gameState = Running}}      
  where
      addB (node:cs) = case nodeName node of 
          Just "Blocks" -> ((node{nodeChildren = block col : (nodeChildren node)}) : cs )  
          _             -> error "spawnNewBock -someone changed the order!"
          
      addNewBlock node _dt = node{ nodeChildren = block col : nodeChildren node }

      (sceneLanded@Scene{ sceneData = sceneState }, col) = randomColour scene


blockLeft :: ShadesScene -> ShadesScene
blockLeft scene
  = addSceneActionDirective scene $ runCustomActionOn "Blocks" leftAction

blockRight :: ShadesScene -> ShadesScene
blockRight scene 
  = addSceneActionDirective scene $ runCustomActionOn "Blocks" rightAction 

-- TODO: missing down arrow to accelerate block downwards
handleEvent :: Event -> SceneState -> Maybe SceneState
handleEvent KeyEvent{ keyEventType = KeyDown, keyEventKeyCode = code} state 
  | code == leftArrowKey  = Just state{ leftPressed  = True }
  | code == rightArrowKey = Just state{ rightPressed = True }
handleEvent _ _           = Nothing 


contact :: SceneState 
        -> PhysicsContact NodeState
        -> (Maybe SceneState, Maybe ShadesNode, Maybe ShadesNode) 
contact state@SceneState{..} PhysicsContact{..}
  | nodeName contactBodyA == Nothing || nodeName contactBodyB == Nothing
  = (Nothing, Nothing, Nothing)  

  | isGround contactBodyA
  = (Just (setLanded state), Nothing, Just $ deactivateBlock contactBodyB) 

  | isGround contactBodyB 
  = (Just (setLanded state), Just $ deactivateBlock contactBodyA, Nothing) 

  -- merge two blocks of the same colour
  | (sameColour contactBodyA contactBodyB) && (sameColumn contactBodyA contactBodyB) 
  = if (above contactBodyA contactBodyB)
       then  (Just (bumpScoreCnt' $ setLanded state), 
              Just $ deactivateBlock $ darkenBlock contactBodyA, 
              Just $ melt contactBodyB)
       else  (Just (bumpScoreCnt' $ setLanded state), 
              Just $ melt contactBodyA, 
              Just $ deactivateBlock $ darkenBlock contactBodyB )

  -- deactivate block
  | isblock contactBodyA
  = (Just (setLanded state ), Just $ deactivateBlock contactBodyA, Nothing)
  | isblock contactBodyB
  = (Just (setLanded state), Nothing, Just $  deactivateBlock contactBodyB)

  | otherwise
  = (Nothing, Nothing, Nothing)

  where
    setLanded :: SceneState  -> SceneState
    setLanded state = state{ gameState = Landed}

    -- bump score count by points for block
    bumpScoreCnt' = bumpScoreCnt 5  
                                  
    melt node = node{nodeActionDirectives = 
                      [runAction $ sequenceActions [  customAction (setName Nothing) 
                                                    , customAction (flip $ \_ -> darkenBlock) 
                                                    , (scaleYTo 0){actionDuration = 1}
                                                    , removeFromParent
                                                    ]
                      ]}

    nextCol node = darkerShade $ nodeUserData node  
                              
    darkenBlock node 
      = node { nodeActionDirectives = [runAction (setTexture $ blockTextures !! (fromEnum $ nextCol node))]
             , nodeUserData = NodeCol $ nextCol node}
                                                   
    
    sameColumn node1 node2 = getCol node1 == getCol node2 
    sameColour node1 node2 = (nodeUserData node1 == nodeUserData node2) && 
                             (nodeUserData node1 /= NodeCol (maxBound :: NodeColour))
    above node1 node2      = getRow node1 > getRow node2

-- convenience functions
sceneResting :: ShadesScene -> Bool
sceneResting scene = not $ or $ map isMoving(nodeChildren $ head $ sceneChildren scene)
  where
    isMoving node = case nodePhysicsBody node of
       Nothing                                     -> False  
       Just PhysicsBody{bodyVelocity = Vector x y} -> abs x + abs y > epsilon

getRow :: ShadesNode -> Int
getRow node = round $ ((pointY $  nodePosition node) - blockHeight / 2) / blockHeight
getCol node = round $ ((pointX $  nodePosition node) - blockWidth / 2) / blockWidth

deactivateBlock :: ShadesNode -> ShadesNode
deactivateBlock node = node{nodeName = Just "Landed"}
 
setName ::  Maybe String -> ShadesNode -> a -> ShadesNode
setName mbName node _ = node{nodeName = mbName}

-- create a new active block with random number to determine color
block :: NodeColour -> ShadesNode
block colour = (spriteWithTexture texture)
  { nodeUserData    = NodeCol colour
  , nodeName        = Just "Block"
  , nodePosition    = Point  (width * 0.5) height 
  , nodePhysicsBody = Just $
                      ( bodyWithRectangleOfSize (Size (blockWidth - 4) blockHeight) Nothing) 
                      { bodyCategoryBitMask    = categoryBitMask [Block]
                      , bodyAllowsRotation     = False
                      , bodyIsDynamic          = True
                      , bodyCollisionBitMask   = categoryBitMask [World, Block]
                      , bodyContactTestBitMask = categoryBitMask [World, Block]
                      , bodyVelocity           = Vector 0 2
                      , bodyFriction           = 0
                      , bodyRestitution        = 0.0
                      , bodyLinearDamping      = 1
                      }
  }
  where
    texture = blockTextures !! (fromEnum colour)

blocks :: ShadesNode
blocks = (node []) { nodeUserData = NoState
                   , nodeName     = Just "Blocks"
                   }

walls :: ShadesNode
walls = (node [groundPhysics, leftWall, rightWall]){nodeUserData = NoState}

groundPhysics :: ShadesNode
groundPhysics = (node [])
                { nodeUserData    = NoState
                , nodePosition    = Point 0 0
                , nodePhysicsBody = Just $
                    (bodyWithEdgeFromPointToPoint (Point 0 0)
                                                  (Point width 0))
                    { bodyCategoryBitMask = categoryBitMask [World] 
                    , bodyLinearDamping = 1                
                    , bodyRestitution = 0
                    }
                , nodeName        = Just "Ground"
                }

score :: ShadesNode
score = (labelNodeWithFontNamed "MarkerFelt-Wide")
        { nodeName      = Just "Score"
        , nodeUserData   = NoState
        , nodePosition  = Point (width / 2) (3 * height / 4)
        , nodeZPosition = 100
        , labelText     = "0"
        }

debug :: ShadesNode
debug = (labelNodeWithFontNamed "MarkerFelt-Wide")
        { nodeName      = Just "debug"
        , nodeUserData  = NoState
        , nodePosition  = Point (width / 2) (height / 2)
        , nodeZPosition = 100
        , labelText     = "-"
        }

gameOverNotice :: ShadesNode
gameOverNotice = (labelNodeWithFontNamed "MarkerFelt-Wide")
                 { nodeUserData  = NoState
                 , nodePosition  = Point (width / 2) (7 * height / 8)
                 , nodeZPosition = 100
                 , labelText     = "Game Over"
                 }


leftWall :: ShadesNode
leftWall = (node [])
           { nodeUserData    = NoState
           , nodePosition    = Point 0 0
           , nodePhysicsBody = Just $
               (bodyWithEdgeFromPointToPoint (Point 0 0)
                                             (Point 0 height))
               { bodyCategoryBitMask = categoryBitMask [World] 
               }
           }

rightWall :: ShadesNode
rightWall = (node [])
            { nodeUserData    = NoState
            , nodePosition    = Point 0 0
            , nodePhysicsBody = Just $
                (bodyWithEdgeFromPointToPoint (Point width 0)
                                              (Point width height))
                { bodyCategoryBitMask = categoryBitMask [World] 
                }
            }
