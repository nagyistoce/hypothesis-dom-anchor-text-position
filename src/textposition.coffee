Range = require("xpath-range").Range
Promise = require('es6-promise').Promise

class SelectorCreator

  name: "TextPositionSelector from text range (either raw or magic)"

  createSelectors: (segmentDescription) ->
    unless segmentDescription.type in ["magic text range", "raw text range"]
      return []

    state = segmentDescription.data?.dtmState
    unless state?
      console.log "DTM state is missing, sorry."
      return []

    r = if segmentDescription.type is "raw text range"
      # TODO: we should be able to do this without converting to magic range.
      new Range.BrowserRange(segmentDescription.range).normalize()
    else
      segmentDescription.range

    # Do we have d-t-m catabilitities?
    return [] unless state.getStartInfoForNode

    # TODO: move to the now API, with getStartOffsetForNode
    startOffset = (state.getStartInfoForNode r.start).start
    endOffset = (state.getEndInfoForNode r.end).end

    # Compose the selector
    type: "TextPositionSelector"
    start: startOffset
    end: endOffset

class AnchoringStrategy

  configure: (@manager) ->

  name: "position"

  priority: 50

  createAnchor: (selectors) =>

    # This strategy depends on dom-text-mapper functionality
    return null unless @manager.domMapper._getStartInfoForNode?

    # We need the TextPositionSelector
    selector = @manager._findSelector selectors, "TextPositionSelector"

    return null unless selector

    new Promise (resolve, reject) =>
      # Get the d-t-m in a consistent state
      @manager.domMapper.prepare("anchoring").then (s) =>
        # When the d-t-m is ready, do this

        content = s.getCorpus()[ selector.start ... selector.end ].trim()
        currentQuote = @manager._normalizeString content
        savedQuote = @manager._getQuoteForSelectors? selectors

        if savedQuote? and currentQuote isnt savedQuote
          # We have a saved quote, let's compare it to current content
          #console.log "Could not apply position selector" +
          #  " [#{selector.start}:#{selector.end}] to current document," +
          #  " because the quote has changed. " +
          #  "(Saved quote is '#{savedQuote}'." +
          #  " Current quote is '#{currentQuote}'.)"
          reject "the saved quote doesn't match"

        # Create a TextPositionAnchor from this data
        resolve
          type: "text position"
          start: selector.start
          end: selector.end
          startPage: s.getPageIndexForPos selector.start
          endPage: s.getPageIndexForPos selector.end
          quote: currentQuote

#  verify: @_verifyPositionAnchor

module.exports =
  creator: SelectorCreator
  strategy: AnchoringStrategy
