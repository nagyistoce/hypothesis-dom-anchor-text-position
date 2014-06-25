Range = require("xpath-range").Range

class SelectorCreator

  name: "TextPositionSelector from text range (either raw or magic)"

  describe: (selection) ->
    return [] unless selection.type in ["magic text range", "raw text range"]

    state = selection.data?.dtmState
    unless state?
      console.log "DTM state is missing, sorry."
      return []

    r = if selection.type is "raw text range"
      # TODO: we should be able to do this without converting to magic range.
      new Range.BrowserRange(selection.range).normalize()
    else
      selection.range

    # Do we have d-t-m catabilitities?
    return [] unless state.getStartInfoForNode

    # TODO: move to the now API, with getStartOffsetForNode
    startOffset = (state.getStartInfoForNode r.start).start
    endOffset = (state.getEndInfoForNode r.end).end

    # Compose the selector
    type: "TextPositionSelector"
    start: startOffset
    end: endOffset

module.exports =
  creator: SelectorCreator