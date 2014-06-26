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

  # Create an anchor using the saved TextPositionSelector.
  # The quote is verified.
  createAnchor: (selectors) =>

    # This strategy depends on dom-text-mapper functionality
    return null unless @manager._document._getStartInfoForNode?

    # We need the TextPositionSelector
    selector = @manager._findSelector selectors, "TextPositionSelector"

    return null unless selector

    new Promise (resolve, reject) =>
      # Get the d-t-m in a consistent state
      @manager._document.prepare("anchoring").then (s) =>
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

  # If there was a corpus change, verify that the text
  # is still the same.
  verifyAnchor: (anchor, reason, data) =>
    # We don't care until the corpus has changed
    return true unless reason is "corpus change"

    new Promise (resolve, reject) =>
      # Prepare d-t-m for action
      @manager._document.prepare("verifying an anchor").then (s) =>
        # Get the current quote
        corpus = s.getCorpus()
        content = corpus[ anchor.start ... anchor.end ].trim()
        currentQuote = @manager._normalizeString content

        # Compare it with the stored one
        resolve (currentQuote is anchor.quote)

module.exports =
  creator: SelectorCreator
  strategy: AnchoringStrategy
