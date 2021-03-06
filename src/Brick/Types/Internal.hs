{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Brick.Types.Internal
  ( ScrollRequest(..)
  , VisibilityRequest(..)
  , vrPositionL
  , vrSizeL
  , Location(..)
  , locL
  , origin
  , TerminalLocation(..)
  , Viewport(..)
  , ViewportType(..)
  , RenderState(..)
  , Direction(..)
  , CursorLocation(..)
  , cursorLocationL
  , cursorLocationNameL
  , Context(..)
  , EventState
  , Next(..)

  , scrollRequestsL
  , viewportMapL
  , observedNamesL
  , vpSize
  , vpLeft
  , vpTop
  )
where

#if !MIN_VERSION_base(4,8,0)
import Data.Monoid
#endif

import Lens.Micro (_1, _2, Lens')
import Lens.Micro.TH (makeLenses)
import Lens.Micro.Internal (Field1, Field2)
import qualified Data.Set as S
import qualified Data.Map as M
import Graphics.Vty (DisplayRegion)

import Brick.Types.TH
import Brick.AttrMap (AttrName, AttrMap)
import Brick.Widgets.Border.Style (BorderStyle)

data RenderState n =
    RS { viewportMap :: M.Map n Viewport
       , scrollRequests :: [(n, ScrollRequest)]
       , observedNames :: !(S.Set n)
       }

data ScrollRequest = HScrollBy Int
                   | HScrollPage Direction
                   | HScrollToBeginning
                   | HScrollToEnd
                   | VScrollBy Int
                   | VScrollPage Direction
                   | VScrollToBeginning
                   | VScrollToEnd

data VisibilityRequest =
    VR { vrPosition :: Location
       , vrSize :: DisplayRegion
       }
       deriving Show

-- | Describes the state of a viewport as it appears as its most recent
-- rendering.
data Viewport =
    VP { _vpLeft :: Int
       -- ^ The column offset of left side of the viewport.
       , _vpTop :: Int
       -- ^ The row offset of the top of the viewport.
       , _vpSize :: DisplayRegion
       -- ^ The size of the viewport.
       }
       deriving Show

-- | The type of viewports that indicates the direction(s) in which a
-- viewport is scrollable.
data ViewportType = Vertical
                  -- ^ Viewports of this type are scrollable only vertically.
                  | Horizontal
                  -- ^ Viewports of this type are scrollable only horizontally.
                  | Both
                  -- ^ Viewports of this type are scrollable vertically and horizontally.
                  deriving Show

type EventState n = [(n, ScrollRequest)]

-- | The type of actions to take upon completion of an event handler.
data Next a = Continue a
            | SuspendAndResume (IO a)
            | Halt a
            deriving Functor

-- | Scrolling direction.
data Direction = Up
               -- ^ Up/left
               | Down
               -- ^ Down/right

-- | A terminal screen location.
data Location = Location { loc :: (Int, Int)
                         -- ^ (Column, Row)
                         }
                deriving Show

suffixLenses ''Location

instance Field1 Location Location Int Int where
    _1 = locL._1

instance Field2 Location Location Int Int where
    _2 = locL._2

-- | The class of types that behave like terminal locations.
class TerminalLocation a where
    -- | Get the column out of the value
    columnL :: Lens' a Int
    column :: a -> Int
    -- | Get the row out of the value
    rowL :: Lens' a Int
    row :: a -> Int

instance TerminalLocation Location where
    columnL = _1
    column (Location t) = fst t
    rowL = _2
    row (Location t) = snd t

-- | The origin (upper-left corner).
origin :: Location
origin = Location (0, 0)

instance Monoid Location where
    mempty = origin
    mappend (Location (w1, h1)) (Location (w2, h2)) = Location (w1+w2, h1+h2)

-- | A cursor location.  These are returned by the rendering process.
data CursorLocation n =
    CursorLocation { cursorLocation :: !Location
                   -- ^ The location
                   , cursorLocationName :: !(Maybe n)
                   -- ^ The name of the widget associated with the location
                   }
                   deriving Show

-- | The rendering context. This tells widgets how to render: how much
-- space they have in which to render, which attribute they should use
-- to render, which bordering style should be used, and the attribute map
-- available for rendering.
data Context =
    Context { ctxAttrName :: AttrName
            , availWidth :: Int
            , availHeight :: Int
            , ctxBorderStyle :: BorderStyle
            , ctxAttrMap :: AttrMap
            }

suffixLenses ''RenderState
suffixLenses ''VisibilityRequest
suffixLenses ''CursorLocation
makeLenses ''Viewport
