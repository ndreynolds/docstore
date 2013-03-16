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

  $('ul.tagit input')
    .on 'focus', ->
      $('ul.tagit').css 'border-color': '#08c'
    .on 'blur', ->
      $('ul.tagit').css 'border-color': '#000'

  $('#document_file').change ->
    id = $(@).data('file-val')
    $('#' + id).html $(@).val().split('\\').pop()

  $('[data-dialog]').click ->
    id = $(@).data('dialog')
    $dialog = $('#' + id)
    $dialog
      .show()
      .find('.cancel-btn').click ->
        console.log 'boom'
        $dialog.hide()
        false
