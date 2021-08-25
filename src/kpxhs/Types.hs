{-# LANGUAGE TemplateHaskell #-}

module Types where

import           Brick.BChan          (BChan)
import qualified Brick.Focus          as F
import           Brick.Types          (Widget)
import qualified Brick.Widgets.Dialog as D
import qualified Brick.Widgets.Edit   as E
import qualified Brick.Widgets.List   as L
import           Control.Concurrent   (ThreadId)
import qualified Data.Map.Strict      as Map
import           Data.Text            (Text)
import           GHC.IO.Exception     (ExitCode)
import           Lens.Micro.TH        (makeLenses)


data Setting = Setting { timeout     :: Maybe Int
                       , dbPath      :: Maybe Text
                       , keyfilePath :: Maybe Text
                       }

data Action = Ls | Clip | Show

data View = PasswordView | BrowserView | SearchView | EntryView | ExitView

data Field = PathField | PasswordField | KeyfileField | BrowserField | SearchField
  deriving (Ord, Eq, Show)

data CopyType = CopyUsername | CopyPassword

data ExitDialog = Clear | Exit | Cancel

-- | (exitcode, stdout, stderr)
type CmdOutput = (ExitCode, Text, Text)

data Event = Login CmdOutput
           | EnterDir Text CmdOutput   -- ^ Text is the currently selected entry
           | ShowEntry Text CmdOutput  -- ^ Text is the currently selected entry
           | ClearClipCount Int
           | Copying (ExitCode, Text)  -- ^ Excludes stdout

data State = State
  { -- | The name of visible entries in the current directory
    _visibleEntries         :: L.List Field Text,
    -- | All the entries (visible or not) that has been loaded from all directories
    -- Mapping between directory name to list of entry names
    _allEntryNames          :: Map.Map Text [Text],
    -- | The name of the entry selected to show details for
    _currentEntryDetailName :: Maybe Text,
    -- | All the entry details that has been opened
    -- Mapping between directory name to (entry names and their details)
    _allEntryDetails        :: Map.Map Text (Map.Map Text Text),
    -- | The currently visible View
    _activeView             :: View,
    -- | The previous View
    _previousView           :: View,
    -- | The string in the bottom of the window
    _footer                 :: Widget Field,
    -- | Determines fields that can be focused and their order
    _focusRing              :: F.FocusRing Field,
    -- | Field for the database path
    _dbPathField            :: E.Editor Text Field,
    -- | Field for the database password
    _passwordField          :: E.Editor Text Field,
    -- | Field for the keyfile path
    _keyfileField           :: E.Editor Text Field,
    -- | Field for the Text in the search bar
    _searchField            :: E.Editor Text Field,
    -- | List of directory names that make up the path of the current directory
    _currentDir             :: [Text],
    -- | The state container for the exit dialog
    _exitDialog             :: D.Dialog ExitDialog,
    -- | Whether the user has copied anything
    _hasCopied              :: Bool,
    -- | The app event channel; contains all the info that needs to be passed from
    -- a background thread to the AppEvent handler
    _chan                   :: BChan Event,
    -- | Number of seconds to wait before clearing the clipboard
    _clearTimeout           :: Int,
    -- | The current clipboard clear countdown thread id
    _countdownThreadId      :: Maybe ThreadId
  }

makeLenses ''State
