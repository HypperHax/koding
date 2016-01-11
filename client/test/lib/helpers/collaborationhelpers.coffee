helpers    = require './helpers.js'
assert     = require 'assert'
ideHelpers = require './idehelpers.js'
utils      = require '../utils/utils.js'

messagePane              = '.message-pane.privatemessage'
notStartedButtonSelector = '.status-bar a.share.not-started'
chatBox                  = '.collaboration.message-pane'
shareButtonSelector      = '.status-bar a.share:not(.loading)'

module.exports =


  isSessionActive: (browser, callback) ->

    browser
      .waitForElementVisible   shareButtonSelector, 20000
      .pause   4000
      .element 'css selector', notStartedButtonSelector, (result) =>
        isActive = if result.status is 0 then no else yes
        callback(isActive)


  startSession: (browser) ->

    chatViewSelector    = '.chat-view.onboarding'
    startButtonSelector = '.chat-view.onboarding .buttons button.start-session'

    @isSessionActive browser, (isActive) ->
      if isActive
        console.log ' ✔ Session is active'
      else
        console.log ' ✔ Session is not started'
        browser
          .click                  shareButtonSelector
          .waitForElementVisible  chatViewSelector, 20000
          .waitForElementVisible  startButtonSelector, 20000
          .click                  startButtonSelector

      browser
        .waitForElementVisible  messagePane, 200000 # Assertion
        .waitForElementVisible  '.status-bar a.share.active', 20000 # Assertion


  leaveSessionFromStatusBar: (browser) ->

    @endSessionFromStatusBar(browser, no)


  endSessionFromStatusBar: (browser, shouldAssert = yes) ->

    statusBarSelector       = '.status-bar .collab-status'
    buttonContainerSelector = statusBarSelector + ' .button-container'

    browser
      .waitForElementVisible  statusBarSelector, 20000
      .waitForElementVisible  statusBarSelector + ' span', 20000
      .click                  statusBarSelector + ' span'
      .waitForElementVisible  buttonContainerSelector, 20000
      .click                  buttonContainerSelector + ' button.end-session'

    @endSessionModal(browser, shouldAssert)


  endSessionFromChat: (browser) ->

    @openChatSettingsMenu(browser)

    browser
      .waitForElementVisible  '.chat-dropdown li.end-session', 20000
      .click                  '.chat-dropdown li.end-session'

    @endSessionModal(browser)


  endSessionModal: (browser, shouldAssert = yes) ->

    buttonsSelector = '.kdmodal .kdmodal-buttons'

    browser
      .waitForElementVisible  '.with-buttons', 20000
      .waitForElementVisible  buttonsSelector, 20000
      .click                  buttonsSelector + ' button.green'
      .pause                  5000

    if shouldAssert
      browser.waitForElementVisible  notStartedButtonSelector, 20000 # Assertion


  openChatSettingsMenu: (browser) ->

    chatSettingsIcon = messagePane + ' .general-header .chat-dropdown .chevron'

    browser
      .waitForElementVisible  messagePane, 20000
      .waitForElementVisible  messagePane + ' .general-header', 20000
      .click                  messagePane + ' .general-header'
      .waitForElementVisible  chatSettingsIcon, 20000
      .click                  chatSettingsIcon


  inviteUser: (browser, username) ->

    console.log " ✔ Inviting #{username} to collaboration session"

    chatSelecor = "span.profile[href='/#{username}']"

    browser
      .waitForElementVisible   '.ParticipantHeads-button--new', 20000
      .click                   '.ParticipantHeads-button--new'
      .waitForElementVisible   '.kdautocompletewrapper input', 20000
      .setValue                '.kdautocompletewrapper input', username
      .pause                   5000
      .element                 'css selector', chatSelecor, (result) ->
        if result.status is 0
          browser.click        chatSelecor
        else
          browser
            .click             '.ParticipantHeads-button--new'
            .pause             500
            .click             '.ParticipantHeads-button--new'
            .pause             500
            .click             chatSelecor


  closeChatPage: (browser) ->

    closeButtonSelector = '.chat-view a.close span'
    chatBox             = '.chat-view'


    browser.element 'css selector', chatBox, (result) =>
      if result.status is 0
        browser
          .waitForElementVisible     chatBox, 20000
          .waitForElementVisible     closeButtonSelector, 20000
          .click                     closeButtonSelector
          .waitForElementNotVisible  chatBox, 20000
          .waitForElementVisible     '.pane-wrapper .kdsplitview-panel.panel-1', 20000
      else
        browser
          .waitForElementVisible     '.pane-wrapper .kdsplitview-panel.panel-1', 20000


  startSessionAndInviteUser: (browser, firstUser, secondUser) ->

    secondUserName         = secondUser.username
    secondUserAvatar       = ".avatars .avatarview[href='/#{secondUserName}']"
    secondUserOnlineAvatar = secondUserAvatar + '.online'
    chatTextSelector       = '.status-bar a.active'

    helpers.beginTest browser, firstUser
    helpers.waitForVMRunning browser

    ideHelpers.closeAllTabs(browser)

    @isSessionActive browser, (isActive) =>

      if isActive then browser.end()
      else
        @startSession browser
        @inviteUser   browser, secondUserName

        browser
          .waitForElementVisible  secondUserAvatar, 60000
          .waitForElementVisible  secondUserOnlineAvatar, 50000 # Assertion
          .waitForElementVisible  chatTextSelector, 50000
          .assert.containsText    chatTextSelector, 'CHAT' # Assertion


  joinSession: (browser, firstUser, secondUser) ->

    firstUserName    = firstUser.username
    secondUserName   = secondUser.username
    sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
    shareModal       = '.share-modal'
    fullName         = shareModal + ' .user-details .fullname'
    acceptButton     = shareModal + ' .kdbutton.green'
    rejectButton     = shareModal + ' .kdbutton.red'
    selectedMachine  = '.sidebar-machine-box.selected'
    filetree         = '.ide-files-tab'
    message          = '.kdlistitemview-activity.privatemessage'
    chatUsers        = "#{chatBox} .chat-heads"
    userAvatar       = ".avatars .avatarview.online[href='/#{firstUserName}']"
    chatTextSelector = '.status-bar a.active'
    sessionLoading   = '.session-starting'

    helpers.beginTest browser, secondUser

    browser.element 'css selector', sharedMachineBox, (result) =>

      if result.status is 0 then browser.end()
      else
        browser
          .waitForElementVisible     shareModal, 500000 # wait for vm turn on for host
          .waitForElementVisible     fullName, 50000
          .assert.containsText       shareModal, firstUserName
          .waitForElementVisible     acceptButton, 50000
          .waitForElementVisible     rejectButton, 50000
          .click                     acceptButton
          .waitForElementNotPresent  shareModal, 50000
          .pause                     3000 # wait for sidebar redraw
          .waitForElementVisible     selectedMachine, 50000
          .waitForElementNotPresent  sessionLoading, 50000
          .waitForElementVisible     chatBox, 50000
          .waitForElementVisible     chatUsers, 50000
          .waitForElementVisible     message, 50000
          .assert.containsText       chatBox, firstUserName
          .assert.containsText       chatBox, secondUserName
          .assert.containsText       filetree, firstUserName
          .waitForElementVisible     userAvatar, 50000 # Assertion
          .waitForElementVisible     chatTextSelector, 50000
          .assert.containsText       chatTextSelector, 'CHAT' # Assertion


  waitParticipantLeaveAndEndSession: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    participantAvatar = ".avatars .avatarview.online[href='/#{participant.username}']"

    if hostBrowser
      browser.waitForElementNotPresent participantAvatar, 60000
      @endSessionFromStatusBar(browser)


  leaveSession: (browser) ->

    participant  = utils.getUser no, 1
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    unless hostBrowser
      @leaveSessionFromStatusBar(browser)
      # assert that no shared vm on sidebar


  initiateCollaborationSession: (browser) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    console.log " ✔ Starting collaboration test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      @startSessionAndInviteUser browser, host, participant
    else
      @joinSession browser, host, participant
