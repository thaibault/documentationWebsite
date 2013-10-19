#!/usr/bin/env require

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion

# region header

# Copyright Torben Sickert 16.12.2012

# License
#    This library written by Torben Sickert stand under a creative commons
#    naming 3.0 unported license.
#    see http://creativecommons.org/licenses/by/3.0/deed.de

###!
    Copyright see require on https://github.com/thaibault/require

    Conventions see require on https://github.com/thaibault/require

    @author t.sickert@gmail.com (Torben Sickert)
    @version 1.0 stable
    @fileOverview
    This plugin provided client side internationalisation support for websites.
###

## standalone
## do ($=jQuery) ->
this.require([['jQuery.Tools', 'jquery-tools-1.0.coffee']], ($) ->
##

# endregion

# region plugins/classes
#
    ###*
        @memberOf jQuery
        @class
        @extends $.Tools
    ###
    class Lang extends $.Tools.class

    # region properties

        currentLanguage: ''
        ###*
            Saves default options for manipulating the Gui's behaviour.

            @property {Object}
        ###
        _options:
            domNodeSelectorPrefix: 'body'
            default: 'enUS'
            domNodeClassPrefix: ''
            fadeEffect: true
            fadeOptions: 'slow'
            domNodes: {}
        _domNodes: {}
        _domNodesToFade: null
        _replacements: []
        __name__: 'Lang'

    # endregion

    # region public methods

        # region special

        initialize: (options={}) ->
            super options
            this.currentLanguage = this._options.default
            this._domNodes = this.grabDomNodes this._options.domNodes
            this

        # endregion

        switch: (language) ->
            this._domNodesToFade = null
            this._replacements = []
            $currentTextNodeToTranslate = false
            self = this
            $(this._options.domNodeSelectorPrefix).find(
                ':not(iframe)'
            ).contents().each(->
                if this.nodeName is '#text' and $(this).text().replace(
                    /^\s+|\s+$/g, ''
                )
                    $currentTextNodeToTranslate = $ this
                else
                    $currentDomNode = $ this
                    if($currentTextNodeToTranslate and
                       this.nodeName is '#comment')
                        $(this.nodeValue).filter('l').each(->
                            $this = $ this
                            if $this.hasClass(
                                self._options.domNodeClassPrefix +
                                language
                            )
                                if self._domNodesToFade is null
                                    self._domNodesToFade = \
                                        $currentTextNodeToTranslate.parent()
                                else
                                    self._domNodesToFade = \
                                        self._domNodesToFade.add(
                                            $currentTextNodeToTranslate.parent())
                                self.log $currentTextNodeToTranslate
                                self.log $currentDomNode
                                self.log $this
                                self._replacements.push(
                                    $textNodeToTranslate: $currentTextNodeToTranslate
                                    $commentNodeToReplace: $currentDomNode
                                    $nodeToReplace: $this)
                                false
                        )
                        $currentTextNodeToTranslate = false
                        true
            )
            this.log this._replacements
            if this._domNodesToFade?
                this._domNodesToFade.fadeOut(this._options.fadeOptions, ->
                    self._switchLanguage(language).currentLanguage = language
                    $(this).fadeIn self._options.fadeOptions
                )
            this

    # endregion

    # region protected methods

        _switchLanguage: (language) ->
            for replacement in this._replacements
                replacement.$textNodeToTranslate.after($(
                    '<!--<l class="' +
                    this.currentLanguage + '">' +
                    replacement.$textNodeToTranslate[0].textContent +
                    '</l>-->'))
                replacement.$textNodeToTranslate[0].textContent = \
                    replacement.$nodeToReplace.text()
                replacement.$commentNodeToReplace.remove()
            this

    # endregion

    ###* @ignore ###
    $.Lang = ->
        self = new Lang
        self._controller.apply self, arguments

# endregion

## standalone
)
