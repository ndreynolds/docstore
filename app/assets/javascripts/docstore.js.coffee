# docstore.coffee
# ---------------

# autocomplete.source: get the tags from the server once and filter client-side.
autocompleteTags = do ->
  tags = []
  filter = (arr, term) ->
    return [] unless term
    $.map arr, (el) -> 
      el if (el.length and term.length and el.substring(0, term.length) == term)
  (request, response) ->
    if tags.length
      response filter(tags, request.term)
    else
      $.getJSON "#{SERVER_ROOT}/documents/tags.json", (data) ->
        response filter(tags = data, request.term)

$ ->
  $('.notice a.close').click ->
    $(@).parent().remove()

  $('#tags').tagit 
    autocomplete: { source: autocompleteTags }
    placeholderText: 'Tags'

  $('ul.tagit input')
    .on 'focus', ->
      $('ul.tagit').addClass('active')
    .on 'blur', ->
      $('ul.tagit').removeClass('active')

  $('#document_file').change ->
    id = $(@).data('file-val')
    $('#' + id).html $(@).val().split('\\').pop()

  $('[data-dialog]').click ->
    id = $(@).data('dialog')
    $dialog = $('#' + id)
    $dialog.show().find('.cancel-btn').click ->
      $dialog.hide()
      false
