# docstore.coffee
# ---------------

# autocomplete.source: get the tags from the server once and filter client-side.
getTags = do ->
  tags = []
  filter = (arr, term) ->
    return [] unless term
    $.map arr, (el) -> 
      if el.length and term.length and el.substring(0, term.length) == term
        el
  (request, response) ->
    if tags.length
      response filter(tags, request.term)
    else
      $.getJSON "#{SERVER_ROOT}/documents/tags.json", (data) ->
        response filter(tags = data)

$ ->
  $('.notice a.close').click ->
    $(@).parent().remove()

  $('#tags').tagit 
    autocomplete: {source: getTags}
    placeholderText: 'Tags'
