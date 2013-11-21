{$} = require 'atom'
CSON = require 'season'
path = require 'path'
emmet = require '../vendor/emmet-core'
editorProxy = require './editor-proxy'
actions = emmet.require("actions")
emmet.define('file', require('./file'));

module.exports =
  editorSubscription: null

  activate: (@state) ->
    unless @actionTranslation
      @actionTranslation = {}
      console.log CSON.readFileSync(path.join(__dirname, "../keymaps/emmet.cson"))
      for selector, bindings of CSON.readFileSync(path.join(__dirname, "../keymaps/emmet.cson"))
        for key, action of bindings
          # Atom likes -, but Emmet expects _
          emmet_action = action.split(":")[1].replace(/\-/g, "_")
          @actionTranslation[action] = emmet_action

    @editorSubscription = atom.rootView.eachEditor (editor) =>
      if editor.attached and not editor.mini
        for action, emmetAction of @actionTranslation
          do (action) =>
              editor.command action, (e) =>
                # a better way to do this might be to manage the editorProxies
                # right now we are setting up the proxy each time
                editorProxy.setupContext(editor)
                syntax = editorProxy.getSyntax()
                if emmet.require("resources").hasSyntax(syntax)
                  emmetAction = @actionTranslation[action]
                  if emmetAction == "expand_abbreviation_with_tab" && !editor.getSelection().isEmpty()
                    e.abortKeyBinding()
                    return
                  else
                    actions.run(emmetAction, editorProxy)
                else
                  e.abortKeyBinding()
                  return
  deactivate: ->
    @editorSubscription?.off()
    @editorSubscription = null
