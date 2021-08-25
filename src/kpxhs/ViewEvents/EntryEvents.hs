{-# LANGUAGE OverloadedStrings #-}

module ViewEvents.EntryEvents (entryDetailsEvent) where

import qualified Brick.Main             as M
import qualified Brick.Types            as T
import           Brick.Widgets.Core     (str)
import           Control.Monad.IO.Class (MonadIO (liftIO))
import           Data.Maybe             (fromMaybe)
import qualified Data.Text              as TT
import qualified Graphics.Vty           as V
import           Lens.Micro             ((&), (.~))

import Common            (maybeGetEntryData)
import Types
    ( CopyType (CopyPassword, CopyUsername)
    , Event (ClearClipCount)
    , Field
    , State
    , View (BrowserView)
    , activeView
    , footer
    )
import ViewEvents.Common
    ( copyEntryCommon
    , handleClipCount
    , liftContinue
    , updateFooter
    )

entryDetailsEvent :: State -> T.BrickEvent Field Event -> T.EventM Field (T.Next State)
entryDetailsEvent st (T.VtyEvent e) =
  case e of
    V.EvKey V.KEsc []        -> M.continue $ returnToBrowser st
    V.EvKey (V.KChar 'p') [] -> liftContinue copyEntryFromDetails st CopyPassword
    V.EvKey (V.KChar 'u') [] -> liftContinue copyEntryFromDetails st CopyUsername
    _                        -> M.continue st
entryDetailsEvent st (T.AppEvent (ClearClipCount count)) =
  M.continue =<< liftIO (handleClipCount st count)
entryDetailsEvent st _ = M.continue st

returnToBrowser :: State -> State
returnToBrowser st =
  st & activeView .~ BrowserView
     & updateFooter

copyEntryFromDetails :: State -> CopyType -> IO State
copyEntryFromDetails st ctype = fromMaybe def (maybeCopy st ctype)
  where
    def = pure $ st & footer .~ str "Failed to get entry name or details!"

maybeCopy :: State -> CopyType -> Maybe (IO State)
maybeCopy st ctype = do
  entryData <- maybeGetEntryData st
  -- Assumes that the title is always the first row
  let splitted = TT.splitOn "Title: " $ head $ TT.lines entryData
  case splitted of
    [_, entry] -> Just $ copyEntryCommon st entry ctype
    _          -> Nothing
