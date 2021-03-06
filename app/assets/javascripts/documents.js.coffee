$ ->
   initPage()
   $(document).on 'page:load', initPage

initPage = ->
  if pageIs 'documents', 'new'
    initDocumentUploadForm()

Dropzone.autoDiscover = false

initDocumentUploadForm = ->
  Dropzone.options.newDocument =
    # forceFallback: true
    paramName: "document[item]"
    autoProcessQueue: false
    clickable: '.dropzone-activator'
    previewsContainer: '.dropzone-previews'
    createImageThumbnails: true
    previewTemplate: Mustache.render($('#dz-preview-template').html())
    uploadMultiple: false
    parallelUploads: 100
    maxFiles: 100
    thumbnailWidth: 64
    thumbnailHeight: 64
    acceptedFiles: $('.dropzone').data('accepts').join(',')
    fallback: ->
      $('.dropzone-activator').remove()
    sending: (file, xhr, formData) ->
      $previewElement = $(file.previewElement)
      title = $previewElement.find('.title-input').val()
      formData.append 'document[title]', title
      tags = $previewElement.find('.tags-input').select2('val').join(',')
      formData.append 'document[tag_list]', tags
      $measurementData = $previewElement.find('.measurement-data')
      if $measurementData.size() > 0 and $measurementData.attr('checked')?
        formData.append 'document[measurement_data]', '1'

    init: ->
      newDocumentDropzone = this
      $(this.element).find("input[type='submit']").on 'click', (e) ->
        e.preventDefault()
        e.stopPropagation()
        newDocumentDropzone.processQueue()

      this.on 'addedfile', (file) ->
        $(file.previewElement).find('.remove-file').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          if file.status == Dropzone.UPLOADING
            Dropzone.confirm newDocumentDropzone.options.dictCancelUploadConfirmation, => newDocumentDropzone.removeFile file
          else
            if newDocumentDropzone.options.dictRemoveFileConfirmation
              Dropzone.confirm newDocumentDropzone.options.dictRemoveFileConfirmation, => newDocumentDropzone.removeFile file
            else
              newDocumentDropzone.removeFile file

        initTagSelector $(file.previewElement).find('.tags-input')

      this.on 'success', (file, response) ->
        $container = $(file.previewElement)
        $container.find('.progress').hide()
        $container.find('.measurement-data-container').remove()
        $titleDisplay = $("<div></div>").text response.title
        $container.find('.title-input').replaceWith $titleDisplay
        $container.find('.tags-input').select2('destroy')
        $container.find('.tags-input').replaceWith renderTags(response.tag_list)
        $container.find('.remove-file').replaceWith $(response.remove_link)
        $('#cancel-btn').text 'Finished'

      this.on 'error', (file, message, xhr) ->
        $container = $(file.previewElement)
        $container.find('.title-input').hide()
        $container.find('.progress').hide()
        $container.find('[data-dz-errormessage]').html(message.join('<br/>')) if $.isArray message

  Dropzone.discover()

renderTags = (tags) ->
  container = $('<div class="tag-list"></div>')
  for tag in tags
    container.append $('<span class="label label-info">' + tag + '</span>')
  container

initTagSelector = ($el) ->
  $el.select2
    tags: $el.data('tags')
    tokenSeparators: [',']
